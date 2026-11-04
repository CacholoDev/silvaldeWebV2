# Plan de abordaje del backend

Desglose del trabajo de backend en **slices pequeños**, agrupados por área,
para ir aprendiendo poco a poco. Complementa [`docs/roadmap.md`](./roadmap.md)
(visión de alto nivel: qué versiones hay y qué entrega cada una) y
[`AGENTS.md`](../AGENTS.md) (reglas de trabajo).

## Cómo usar este documento

Al abrir una sesión de trabajo:

1. Lee el roadmap para saber en qué **versión** estamos.
2. Lee este documento para saber en qué **slice** exacto vamos.
3. Antes de empezar un slice, el agente lo explica en profundidad (qué entra,
   qué queda fuera y cómo se prueba a mano) y espera tu OK (regla de
   `AGENTS.md`, «Ritmo de trabajo y modelo mental»).

Leyenda: ✅ hecho · 🚧 en curso · ⬜ pendiente

## Relación con el roadmap

Los grupos de slices de abajo se integran en las fases de
[`docs/roadmap.md`](./roadmap.md). Los nombres de grupo no son versiones: la
versión la define el roadmap.

- **Autenticación** (modelos, registro/login/logout, recuperación) y
  **Clientes** (roles, perfil, consentimiento) → **v0.2.0**.
- **Catálogo** (categorías, variantes e imágenes, búsqueda) → **v0.3.0**.
- **Carrito** (invitado y registrado) → **v0.4.0**.
- **Pedidos** (checkout, estados, email, detalle) → **v0.5.0**.
- **Métricas** y **panel de administración** → **v0.6.0**.
- **Lanzamiento** → **v1.0.0**.

## Estado actual

- **Hecho** (slices 1-18b): autenticación, usuarios y catálogo completos
  (modelos, login/logout, signup, recuperación de contraseña, roles, perfil,
  consentimiento, imágenes, seed, búsqueda, vistas públicas con accesibilidad
  y SEO, tema claro/oscuro e i18n). Publicado como `v0.2.0` y `v0.3.0`.
- **En curso** (v0.4.0, rama `feat/shopping-cart`): carrito. Los slices 19-24
  están **terminados** (modelos, services, añadir desde la ficha con contador,
  página `/cart`, fusión al login y purge de caducados). El código de la
  versión está completo.
- **Siguiente**: cierre de v0.4.0 — code review de la versión, CHANGELOG,
  `bin/ci` en verde, PR #14 y publicación.

---

## Autenticación: modelos ✅

1. ✅ **User** — migración, validaciones, `has_secure_password`, factory y spec.
2. ✅ **PasswordResetToken** — migración, expiración y scopes, factory y spec.
3. ✅ **Session + Current + concern Authentication** — sesión por cookie, usuario actual y specs.

## Autenticación: registro, login y logout ✅

4. ✅ **Rutas de auth + `sessions` controller** (login/logout) + request spec. *(define `login_path`, cierra el spec rojo actual)*
5. ✅ **`users` controller** (signup) + service `Users::Register` + request spec.
6. ✅ **Vistas de login/signup** + navegación + selector de idioma + i18n.

## Autenticación: recuperación de contraseña ✅

7. ✅ **`passwords` controller** (solicitar reset) + mailer + job.
8. ✅ **`passwords` controller** (editar/actualizar) + vistas + specs.

## Clientes: roles, perfil y consentimiento ✅

9. ✅ **Columna `role`** en `User` (enum customer/admin) + migración.
10. ✅ **Perfil del cliente** (ver/editar) + controller + vistas.
11. ✅ **Consentimiento de comunicaciones** (columna + toggle + spec).

## Catálogo: modelos ✅

12. ✅ **Modelo `Category`** + migración + factory + spec.
13. ✅ **Modelo `Product`** + migración + factory + spec (slug automático,
    precio en céntimos, categoría obligatoria).
14. ✅ **Modelo `Variant`** + migración + factory + spec (stock y precio
    opcional que sobrescribe al del producto).

## Catálogo: imágenes y datos de ejemplo

15. ✅ **Imágenes de producto** con Active Storage (tipos JPEG/PNG/WebP,
    5 MB por imagen, 10 imágenes por producto).
16. ✅ **Seed** de categorías, productos y variantes de ejemplo (idempotente,
    con fotos demo en `db/seeds/images/`).

## Catálogo: búsqueda y navegación

17. ✅ **Servicio de búsqueda** (`Catalog::Search`) + spec.

## Catálogo: vistas públicas (18a back / 18b front)

18a. ✅ **Vistas públicas — parte de back**: rutas, controllers del dominio
    `Catalog::` (landing, productos, categorías), integración con
    `Catalog::Search`, decorators para el formato de precios, vistas
    funcionales con i18n y request specs. URLs: `/` (landing), `/products`,
    `/products/:slug`, `/categories/:slug`; la búsqueda usa `/products?q=`.
18b. ✅ **Vistas públicas — parte de front**: diseño con Tailwind — landing
    con productos destacados, ofertas y galería de fotos, tarjetas de
    producto con imágenes, precios y disponibilidad, diseño responsive y
    accesibilidad visual (WCAG 2.2 AA) más la base de SEO en página
    (títulos, descripciones, canónicas, Open Graph, JSON-LD, sitemap).

## Carrito: modelos y services (v0.4.0)

19. ✅ **Modelos `Carts::Cart` y `Carts::CartItem`** + `Carts::Search` +
    factories + specs (precio congelado al añadir, índice único
    variante/carrito y caducidad a los 6 meses de inactividad).
20. ✅ **Services `Carts::AddItem`, `Carts::UpdateQuantity` y
    `Carts::RemoveItem`** + carrito de invitada en la sesión (el `cart_id`
    viaja en la sesión y el carrito se crea al primer añadir) + specs de cada
    service. `AddItem` suma cantidades cuando la variante ya está en el
    carrito y congela el precio desde `variant.effective_price_cents`.

## Carrito: UI y fusión (v0.4.0)

21. ✅ **Añadir al carrito desde la ficha de producto** (selector de variante
    + cantidad + contador del carrito en el header con Turbo Frame) + request
    specs. El contador se actualiza al instante con Turbo Streams (sin
    recargar) y el formulario tiene fallback HTML sin JavaScript.
22. ✅ **Página `/cart`** (líneas, cantidades, subtotales, total y estado
    vacío) con Turbo Frames, sin recargas. El contador del header enlaza a la
    página y cada línea solo se puede tocar desde su propio carrito (404 si se
    intenta con una línea ajena).
23. ✅ **Fusión al login**: carrito de invitada + carrito de cuenta = sumar
    cantidades de las variantes comunes (2 + 1 = 3), mover las líneas solo del
    invitado con su precio congelado y borrar el carrito de invitada. Un
    carrito de otra cuenta jamás se toca. Specs de servicio e integración
    (incluye el caso de conflicto).
24. ✅ **Purge de carritos caducados** (`Carts::PurgeExpired` + job recurrente
    de Solid Queue, silencioso, diario a las 3am en producción) + specs.

## Pedidos: checkout y estados

25. ⬜ **Modelos `Order` y `OrderItem`** + máquina de estados del pedido con
    **AASM** (`pending → confirmed → shipped → delivered`, o `cancelled`) +
    migración + factories + specs. Al conectar pedidos con variantes, revisar
    el `dependent: :destroy` de `Product` → `Variant`: no se podrá borrar un
    producto cuyas variantes aparezcan en pedidos confirmados.
26. ⬜ **Servicio de checkout** con transacción + spec. El descuento de stock
    se hace con bloqueo de fila (transacción + `with_lock`) y rollback
    completo si falla: dos pedidos simultáneos no pueden vender la misma
    unidad.

## Pedidos: email y detalle

27. ⬜ **Mailer de confirmación de pedido** + job.
28. ⬜ **Detalle y listado de pedidos** del cliente + vistas.

## Métricas

29. ⬜ **Consultas/servicio de métricas** (ventas, productos, clientes) + specs.
30. ⬜ **Vista de métricas** para el panel.

## Panel de administración

31. ⬜ **Namespace `/admin`** + autorización por rol.
32. ⬜ **CRUDs de productos, pedidos y usuarios** en admin.

## Lanzamiento

33. ⬜ Seguridad, contenidos legales y pasarela de pago (con especificación propia).
