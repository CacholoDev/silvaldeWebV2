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
   `AGENTS.md`, «Cómo trabajamos»).

Leyenda: ✅ hecho · 🚧 en curso · ⬜ pendiente

## Relación con el roadmap

Los grupos de slices de abajo se integran en las fases de
[`docs/roadmap.md`](./roadmap.md). Los nombres de grupo no son versiones: la
versión la define el roadmap.

- **Autenticación** (modelos, registro/login/logout, recuperación) y
  **Clientes** (roles, perfil, consentimiento) → **v0.2.0**.
- **Catálogo** (categorías, variantes e imágenes, búsqueda) → **v0.3.0**.
- **Carrito** (invitado y registrado) → **v0.4.0**.
- **Endurecimiento** (auditoría completa) → **v0.4.1**.
- **Pedidos** (checkout con recogida y pago offline, estados, email,
  detalle) → **v0.5.0**.
- **Panel de administración** y **métricas** → **v0.6.0**.
- **Envío a domicilio** → **v0.7.0**.
- **Puesta en producción** → **v0.8.0**.
- **Pagos online** (Stripe y PayPal) → **v0.9.0**.
- **Lanzamiento** (legal, RGPD, rendimiento) → **v1.0.0**.

## Estado actual

- **Hecho** (slices 1-18b): autenticación, usuarios y catálogo completos
  (modelos, login/logout, signup, recuperación de contraseña, roles, perfil,
  consentimiento, imágenes, seed, búsqueda, vistas públicas con accesibilidad
  y SEO, tema claro/oscuro e i18n). Publicado como `v0.2.0` y `v0.3.0`.
- **Hecho y publicado** (`v0.4.0`, 2026-11-10): carrito. Los slices 19-24 están
  terminados e integrados en `main` (PRs #14 y #15): modelos, services, añadir
  desde la ficha con contador, página `/cart`, fusión al login y purge de
  caducados. Endurecido después en `chore/project-health` (reintento ante
  carreras, memoización de `current_cart` y system spec).
- **En curso** (`v0.4.1`): endurecimiento tras la auditoría completa
  (PR #25).
- **Siguiente**: v0.5.0 (pedidos).

---

## Autenticación: modelos ✅

1. ✅ **User** — migración, validaciones, `has_secure_password`, factory y spec.
2. ✅ **PasswordResetToken** — migración, expiración, factory y spec (las
   consultas viven en `Auth::Search`).
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

## Pedidos: modelos y estados (v0.5.0)

25. ⬜ **Gema AASM + modelos `Orders::Order` y `Orders::OrderItem`** +
    migraciones (CHECK de stock, cantidades y precios) + factories + specs.
    Número de pedido público, datos de contacto, tienda de recogida,
    `payment_method` y `payment_status`, precios congelados. Estados con
    AASM y registro de transiciones (quién y cuándo).
26. ⬜ **`Orders::Search`** (pedidos de una cuenta, pedido por número y
    token del enlace) + specs.

## Pedidos: checkout (v0.5.0)

27. ⬜ **Servicio `Orders::Checkout`** en una transacción: valida el carrito,
    bloquea las variantes (`with_lock`), descuenta stock, crea el pedido y
    vacía el carrito; rollback completo si falla. Specs de éxito, falta de
    stock y concurrencia.
28. ⬜ **Pantalla de checkout** (contacto, tienda de recogida, método de
    pago, condiciones de venta) con o sin cuenta + request y system specs.
29. ⬜ **`Orders::Cancel`** (devuelve el stock) y las demás transiciones como
    services + specs.

## Pedidos: email y detalle (v0.5.0)

30. ⬜ **Mailer de pedido** (confirmación con datos de transferencia/Bizum o
    de recogida; cambios de estado) + job + previews.
31. ⬜ **«Mis pedidos»** (con cuenta) y **detalle por enlace firmado** (sin
    cuenta) + vistas + specs de acceso ajeno (404).

## Panel de administración (v0.6.0)

32. ⬜ **Namespace `/admin`** + `before_action` de rol admin + tarea
    `admin:create` + specs de acceso denegado.
33. ⬜ **Pedidos en admin:** listado con filtros y acciones por estado +
    justificante imprimible.
34. ⬜ **Productos en admin:** CRUD, fotos, variantes, stock y archivado
    (`archived_at`) en lugar de borrado.
35. ⬜ **Usuarias en admin** y **métricas básicas**.

## Envío a domicilio (v0.7.0)

36. ⬜ **Direcciones** (en el pedido y libreta de la cuenta) + specs.
37. ⬜ **Tarifas de envío** (tabla editable en admin) y coste en el checkout.
38. ⬜ **Rama de estados de envío** (`shipped`, `delivered`) con número de
    seguimiento y email.

## Puesta en producción (v0.8.0)

39. ⬜ VPS de pruebas con Kamal, dominio y HTTPS; MySQL como accessory.
40. ⬜ Copias de seguridad automáticas y restauración probada; fotos en
    almacenamiento externo y variantes de imagen (`ruby-vips`).
41. ⬜ Email transaccional (SMTP, SPF/DKIM/DMARC) y monitorización (errores,
    `/up`, jobs fallidos).
42. ⬜ Despliegue desde GitHub Actions, staging y proceso de migraciones.

## Pagos online (v0.9.0)

43. ⬜ **Stripe Checkout** + webhook verificado e idempotente + specs.
44. ⬜ **PayPal** + webhook + specs.
45. ⬜ Caducidad de pedidos sin pagar (libera stock) y reembolsos desde admin.

## Lanzamiento (v1.0.0)

46. ⬜ Textos legales, condiciones de venta y desistimiento (14 días).
47. ⬜ RGPD: borrar y exportar la cuenta.
48. ⬜ CSP, paginación, caché y pasada final de accesibilidad y rendimiento.
