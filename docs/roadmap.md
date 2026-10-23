# Roadmap de Silvalde Web

Plan de fases del proyecto y referencia de control. Cada fase terminada e
integrada en `main` publica una versión (ver [versioning.md](./versioning.md)).
Este documento se actualiza conforme avanza el proyecto.

El desglose fino del backend en **slices** está en
[`backend-plan.md`](./backend-plan.md).

Leyenda: ✅ hecho · 🚧 en curso · ⬜ pendiente

---

## La primera versión de la web (objetivo: v1.0.0)

Cuando publiquemos la `v1.0.0`, esto es lo que existirá:

### Lo que podrá hacer una visitante o clienta

- Entrar a la web y **ver el catálogo** de productos de decoración organizado
  por categorías, con fotos, precios, variantes y disponibilidad.
- **Buscar** productos y navegar sin necesidad de cuenta.
- **Registrarse**, iniciar/cerrar sesión y recuperar su contraseña.
- Tener un **carrito** (con o sin cuenta) y **hacer pedidos**.
- Ver el **detalle y estado de sus pedidos** y recibir email de confirmación.
- Elegir si quiere recibir **ofertas y rebajas** (consentimiento explícito,
  revocable).

### Lo que podrá hacer la tienda (administración)

- Entrar a un **panel `/admin` protegido por rol** (solo usuarias admin).
- Gestionar **usuarios, productos, pedidos y facturas**.
- Ver **métricas básicas** y la versión de la app en el footer.

### Lo que NO entra en la primera versión

Sin una especificación aprobada aparte (regla de `AGENTS.full.md`):

- **Pasarela de pago real** (tarjeta, Bizum, PayPal…): los pedidos se registran
  y el pago se acuerda como en la tienda física hasta que se especifique.
- **Facturación fiscal** automatizada.
- **Campañas de marketing** (el consentimiento se guarda desde el principio,
  pero los envíos llegarán más adelante).
- Integraciones externas (envíos, ERP, redes sociales…).

---

## Fases

### ✅ v0.1.0 — Base del proyecto

Estructura Rails 8.1, documentación del proyecto y de agentes, versionado y
flujo de trabajo con git. Publicada el 2026-10-11 con el tag `v0.1.0`.

### ✅ v0.2.0 — Autenticación y usuarios

Registro, inicio/cierre de sesión y recuperación de contraseña; roles
`customer`/`admin`; perfil de cliente; consentimiento de comunicaciones.
Construida por slices pequeños (11 slices, 103 specs en verde). Publicada el
2026-10-24 con el tag `v0.2.0`.

### ⬜ v0.3.0 — Catálogo

**Qué se hace:** categorías y productos con variantes, imágenes y
disponibilidad; navegación pública por categorías y búsqueda.

**Cómo se hará:** modelos `Category`, `Product` y `Variant` con sus índices y
validaciones; imágenes con Active Storage (ya incluido en Rails); servicio de
búsqueda para no ensuciar el controlador; vistas públicas con Tailwind;
`db/seeds.rb` con productos de ejemplo para trabajar.

### ⬜ v0.4.0 — Carrito

**Qué se hace:** carrito para visitantes y clientas registradas; cantidades y
variantes; el carrito sobrevive al iniciar sesión.

**Cómo se hará:** modelos `Cart` y `CartItem` (relación con datos propios:
cantidad, precio en el momento de añadir). El carrito de invitada vive en la
sesión y se fusiona con el de la cuenta al hacer login. Añadir/quitar con
Turbo Frames para no recargar la página.

### ⬜ v0.5.0 — Pedidos

**Qué se hace:** checkout (sin pasarela de pago de momento), pedidos con
estados, detalle visible para la clienta y email de confirmación.

**Cómo se hará:** modelos `Order` y `OrderItem` con los precios congelados en
el momento de la compra; máquina de estados del pedido con **AASM** —estados
`pending → confirmed → shipped → delivered`, o `cancelled` (en la UI:
pendiente → confirmado → enviado → entregado, o cancelado)—; servicio de
checkout con transacción (crea pedido + vacía carrito o falla todo); emails
con Action Mailer.

### ⬜ v0.6.0 — Panel de administración

**Qué se hace:** autorización por rol aplicada en servidor; gestión de
usuarios, productos, pedidos y facturas; métricas básicas y versión de la app
visible en el footer del admin (`SilvaldeWebV2::APP_VERSION`).

**Cómo se hará:** rutas bajo el namespace `/admin`; un `before_action` que
exige rol `admin` en servidor (nunca basta con ocultar botones); Pundit como
candidato si los permisos se vuelven más finos (decidir en esta fase); CRUDs
con las mismas vistas parciales y formato del storefront para coherencia.

### ⬜ v1.0.0 — Lanzamiento público

Endurecimiento de seguridad, rendimiento y contenidos legales (aviso legal,
privacidad, cookies). Pasarela de pago y facturación fiscal: requieren su
propia especificación antes de implementarse.

---

## Cómo se trabaja cada fase (resumen del flujo)

1. Crear la rama desde `main`: `git switch -c feat/<name>`.
2. El agente explica el plan antes de tocar código (qué se crea y por qué).
3. Implementar en commits pequeños con Conventional Commits.
4. Validar con `bin/ci` (tests + rubocop + brakeman + audits).
5. Integrar en `main`, publicar la versión según
   [versioning.md](./versioning.md) y marcar la fase como ✅ aquí.

## Notas

- Las fases pueden solaparse, pero no se integra nada a medias en `main`.
- Cualquier funcionalidad fuera de esta lista necesita antes su especificación
  (ver `AGENTS.full.md`, sección «Cambios y documentación»).
