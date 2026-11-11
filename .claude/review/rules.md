# Perfil de review de silWeb

Lo usa la skill global `/project-review` (repo `agent-dotfiles`): este
checklist **manda sobre el genérico**. Las reglas de fondo están en
`AGENTS.md` y `AGENTS.full.md`; aquí se concretan para revisar.

- Ejemplos reales de violaciones: [`examples.md`](./examples.md).
- Comprobaciones automáticas propias: [`checks.tsv`](./checks.tsv) (las
  ejecuta `rails_checks.sh` junto a las genéricas).
- silWeb **no** usa Discard, AASM, Pundit, Draper ni ViewComponent: no
  reportes su ausencia.

## Checklist por tipo de archivo (pasada 1)

### Controllers (`app/controllers/**`)
- [ ] Solo orquestan: params → servicio o `Search` → responder. Sin reglas de
      negocio y sin ActiveRecord directo (`Model.find/where/create…`,
      `authenticate_by`). Excepción: concern `Authentication`.
- [ ] Lecturas con `<Dominio>::Search`; con `find_*!` cuando el recurso debe
      existir (404). Construir `Model.new` para un formulario está permitido.
- [ ] **Propiedad**: todo lo que pertenece a alguien se busca **a través de su
      dueño** (`Carts::Search.find_item_by_id!(current_cart, params[:id])`,
      `current_user`), nunca solo por id (IDOR).
- [ ] Strong params con `permit` explícito. Sin `permit!` y sin pasar `params`
      entero a un service.
- [ ] Parámetros numéricos normalizados en el borde (`params[:quantity].to_s.to_i`):
      un array o un hash no puede provocar un 500.
- [ ] Estrategia de errores: el service devuelve el objeto con `errors` → el
      controller decide con `errors.any?`/`errors.empty?`, y en el fallo responde
      `:unprocessable_content` (HTML `render`, o `turbo_stream` con status).
- [ ] Respuestas `turbo_stream` **y** fallback HTML (`format.html`) cuando la
      acción se usa desde un formulario.
- [ ] Mensajes con `t(...)`; nada de texto literal en `notice:`/`alert:`.
- [ ] `private` está permitido aquí (strong params y helpers de render).

### Services (`app/services/<dominio>/**`)
- [ ] Un caso de uso por service (`self.call(...)` con keywords), una sola
      responsabilidad. Si hace dos cosas, son dos services.
- [ ] **Lecturas por el `Search` del dominio**, también desde un service. Un
      service de caso de uso no hace `Model.where/find_by` (escrituras
      masivas acotadas como `Session.where(user:).destroy_all` se toleran;
      márcalas si crecen).
- [ ] `search.rb`: métodos de clase, `includes` donde se itera (N+1), `nil`
      seguro (`return nil if id.blank?` sin consulta inútil), y documentación
      breve de qué devuelve.
- [ ] Transacción cuando escribe en varias tablas. Bang (`save!`, `update!`)
      para invariantes; sin bang solo cuando el usuario puede corregir el
      error, y entonces devuelve el objeto con `errors`.
- [ ] Sin `rescue` genérico. Solo errores conocidos (p. ej.
      `ActiveRecord::RecordNotUnique` con un reintento acotado).
- [ ] Concurrencia: lo que dependa de unicidad tiene índice único en BD (no
      basta la validación); stock y dinero con `with_lock` dentro de la
      transacción.
- [ ] Rechaza en el borde los valores imposibles (cantidades ≤ 0, ids en
      blanco) añadiendo un error, no fallando más adentro.

### Models (`app/models/<dominio>/**`)
- [ ] Solo asociaciones, validaciones, constantes de dominio y métodos **sin
      parámetros** sobre su estado (`available?`, `expired?`).
- [ ] **Ninguna consulta**: ni `where`, ni `find_by`, ni `scope`, ni
      `default_scope`. Las vigila el cop `Silvalde/NoQueriesInModels`.
- [ ] No declaran `model_name` ni `ActiveModel::Name`: eso lo resuelve
      `ApplicationRecord`.
- [ ] Toda validación de unicidad o integridad tiene su índice o constraint en
      la migración.

### Decorators (`app/decorators/**`)
- [ ] Heredan de `ApplicationDecorator` (`SimpleDelegator`). Solo formato
      (precios con `euros`, etiquetas con `I18n.t`). Sin consultas, sin
      escribir y sin reglas de negocio duplicadas.
- [ ] Dinero siempre en céntimos (`*_cents` integer); se formatea solo aquí o
      con `format_cents`.

### Vistas y partials (`app/views/**`)
- [ ] Sin consultas ni llamadas a `Search`: los datos llegan del controller
      (variables o `locals`).
- [ ] Todo texto visible con `t(...)`. Formularios con `label` asociado
      (`sr-only` si no se ve), `dom_id` para los ids, `alt` en imágenes.
- [ ] Los ids que actualiza `turbo_stream.update("x")` existen en la vista
      (`id="x"` o `turbo_frame_tag "x"`).
- [ ] Enlaces que salen de un `turbo_frame` llevan `data: { turbo_frame: "_top" }`.
- [ ] Tailwind con los tokens existentes (`text-muted`, `border-line`,
      `bg-paper`…). Sin estilos inline ni colores nuevos sin justificar.

### Jobs (`app/jobs/**`)
- [ ] Delegan en un service (el job solo programa y llama). Idempotentes y
      seguros si se ejecutan dos veces.

### Migraciones (`db/migrate/**`)
- [ ] Reversibles. Índices en claves foráneas y búsquedas. Si una referencia
      lleva `index: false`, debe haber un índice compuesto que empiece por esa
      columna.
- [ ] Sin borrar ni renombrar columnas con datos sin un plan en fases. Dinero
      en integer (céntimos), nunca float.

### Specs (`spec/**`)
- [ ] Hay spec para cada comportamiento nuevo (TDD), incluidos los bordes:
      nil o en blanco, negativos, duplicados, params con forma inesperada
      (array), recurso ajeno (404), carrera si aplica.
- [ ] **Tests existentes modificados**: márcalo siempre y comprueba que fue por
      un cambio real de contrato (p. ej. una consulta que se mueve a un
      `Search`), sin perder cobertura.
- [ ] Flujos de UI con Turbo cubiertos con un system spec (`spec/system/`).
- [ ] Sin `xit`, `fit`, `focus` ni `skip`.

## Entre capas: lo propio de silWeb

El método general (campo de punta a punta, estrategia de errores, i18n, rutas
y Turbo) está en `/project-review`. En silWeb, además:

- **Locales**: un único `config/locales/es.yml` y `en.yml` (sin carpeta
  `models/`). Toda clave nueva va en los dos; el género en español debe
  concordar («carrito actualizado», «cantidad actualizada»).
- **Estrategia de errores**: los services de formulario devuelven el objeto
  con `errors` → el controller decide con `errors.any?`/`errors.empty?` y
  responde `:unprocessable_content`, tanto en HTML como en `turbo_stream`.
- **Turbo**: cada `turbo_stream.update("x")` tiene su `id="x"` en la vista;
  mensajes de feedback en un elemento con `role="status"`
  (`cart_feedback`). Fallback HTML (`format.html`) en toda acción de
  formulario.
- **Dinero**: `*_cents` integer en migración, modelo y service; solo se
  formatea en decorators (`euros`) o con `format_cents`.
