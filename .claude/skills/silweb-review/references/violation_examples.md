# Ejemplos de violaciones en silWeb

Casos reales o muy cercanos a lo que ha pasado en el proyecto. Cada uno indica
la regla de `AGENTS.md`/`AGENTS.full.md` y la forma correcta.

## Lecturas fuera del `Search`

**Scope en el modelo y consulta desde un service** (pasó con
`Auth::PasswordResetToken` antes de la 0.4.0):

```ruby
# ❌ app/models/auth/password_reset_token.rb
scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

# ❌ app/services/auth/reset.rb
token = PasswordResetToken.active.find_by(token_digest: digest)
```

```ruby
# ✅ app/services/auth/search.rb
def self.active_password_reset_tokens
  PasswordResetToken.where(used_at: nil).where("expires_at > ?", Time.current)
end

# ✅ app/services/auth/reset.rb
token = Search.active_password_reset_tokens.find_by(token_digest: digest)
```

Regla: los models no consultan, y las lecturas van al `Search` del dominio,
también desde los services. El cop detecta el scope; la consulta desde el
service la detectan el script (como AVISO) y la review.

**Consulta en un controller:**

```ruby
# ❌
variant = Catalog::Variant.find(params[:variant_id])
# ✅
variant = Catalog::Search.variant_by_id!(params[:variant_id])
```

## Propiedad (IDOR)

```ruby
# ❌ cualquiera puede borrar la línea de otro carrito cambiando el id
item = Carts::Search.find_item_by_id!(params[:id])
# ✅ se busca a través del carrito de quien hace la petición → 404 si no es suyo
item = Carts::Search.find_item_by_id!(current_cart, params[:id])
```

## Entradas en el borde

**Params con forma inesperada** (hallazgo de la review de la 0.4.0):

```ruby
# ❌ quantity[]=1 llega como Array → NoMethodError → 500
quantity: params[:quantity].to_i
# ✅
quantity: params[:quantity].to_s.to_i
```

**Valores imposibles** (hallazgo de la review de la 0.4.0: añadir `-3` a una
línea de 10 la dejaba en 7 y decía «Añadido al carrito»):

```ruby
# ✅ Carts::AddItem rechaza antes de tocar la BD
if quantity < 1
  item = CartItem.new(cart:, variant:, quantity:)
  item.errors.add(:quantity, :greater_than_or_equal_to, count: 1)
  return item
end
```

**Consulta inútil** (hallazgo de la review de la 0.4.0: un visitante sin
carrito lanzaba una consulta en cada página):

```ruby
# ✅
def self.find_active_cart(id)
  return nil if id.blank?

  active.find_by(id: id)
end
```

## Concurrencia

```ruby
# ❌ la validación de unicidad sola no evita el doble clic
validates :variant_id, uniqueness: { scope: :cart_id }

# ✅ índice único en la BD + reintento acotado en el service
add_index :cart_items, %i[cart_id variant_id], unique: true

begin
  add(...)
rescue ActiveRecord::RecordNotUnique
  attempts += 1
  raise if attempts > 1
  retry
end
```

El stock (v0.5.0) va con `with_lock` dentro de la transacción.

## Errores

```ruby
# ❌ rescue genérico: esconde bugs y devuelve un falso éxito
def self.call(...)
  ...
rescue => e
  nil
end

# ✅ el service devuelve el objeto con errors cuando el usuario puede corregirlo
def self.call(user, attributes)
  user.update(attributes)
  user
end

# ✅ el controller decide con errors y responde 422 si falla
if @user.errors.any?
  render :edit, status: :unprocessable_content
else
  redirect_to profile_path, notice: t("profiles.flash.updated")
end
```

## Vistas, Turbo e i18n

```erb
<%# ❌ texto literal, id a mano, input sin label %>
<h2>Tu cesta</h2>
<div id="cart_item_<%= item.id %>">
<%= f.number_field :quantity %>

<%# ✅ %>
<h2><%= t("cart.page_title") %></h2>
<tr id="<%= dom_id(item) %>">
<%= f.label :quantity, t("cart.quantity"), for: dom_id(item, :quantity), class: "sr-only" %>
<%= f.number_field :quantity, id: dom_id(item, :quantity), min: 1 %>
```

```ruby
# ❌ el controller actualiza "cart_total", pero la vista no tiene ese id
turbo_stream.update("cart_total", ...)
```

```erb
<%# ❌ dentro de un turbo_frame, el enlace intenta cargar en el frame: "Content missing" %>
<%= link_to item.variant.product.name, product_path(item.variant.product.slug) %>
<%# ✅ %>
<%= link_to item.variant.product.name, product_path(item.variant.product.slug),
      data: { turbo_frame: "_top" } %>
```

Una clave que existe en `es.yml` y no en `en.yml` es un hallazgo **ALTO**: la
web en inglés muestra «translation missing».

## Dinero

```ruby
# ❌
t.decimal :price
# ✅ céntimos en integer; el formato solo en el decorator
t.integer :price_cents, null: false
def formatted_price = euros(price_cents)
```
