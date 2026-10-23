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

- Rama de trabajo: `feat/authenticationV2`.
- **Hecho** (slices 1-7): modelos de auth, login/logout, signup, vistas y
  solicitud de reset de contraseña (parte 1). **77 specs en verde**.
- **Siguiente**: slice 8 (poner nueva contraseña: `passwords#edit`/`update`).

---

## Autenticación: modelos ✅

1. ✅ **User** — migración, validaciones, `has_secure_password`, factory y spec.
2. ✅ **PasswordResetToken** — migración, expiración y scopes, factory y spec.
3. ✅ **Session + Current + concern Authentication** — sesión por cookie, usuario actual y specs.

## Autenticación: registro, login y logout ✅

4. ✅ **Rutas de auth + `sessions` controller** (login/logout) + request spec. *(define `login_path`, cierra el spec rojo actual)*
5. ✅ **`users` controller** (signup) + service `Users::Register` + request spec.
6. ✅ **Vistas de login/signup** + navegación + selector de idioma + i18n.

## Autenticación: recuperación de contraseña 🚧

7. ✅ **`passwords` controller** (solicitar reset) + mailer + job.
8. ⬜ **`passwords` controller** (editar/actualizar) + vistas + specs.

## Clientes: roles, perfil y consentimiento

9. ⬜ **Columna `role`** en `User` (enum customer/admin) + migración.
10. ⬜ **Perfil del cliente** (ver/editar) + controller + vistas.
11. ⬜ **Consentimiento de comunicaciones** (columna + toggle + spec).

## Catálogo: categorías y productos

12. ⬜ **Modelo `Category`** + migración + factory + spec.
13. ⬜ **Modelo `Product`** + migración + factory + spec.
14. ⬜ **Seed** de categorías y productos de ejemplo.

## Catálogo: variantes e imágenes

15. ⬜ **Modelo `Variant`** + migración + factory + spec.
16. ⬜ **Imágenes de producto** con Active Storage.

## Catálogo: búsqueda y navegación

17. ⬜ **Servicio de búsqueda** (`Catalog::Search`) + spec.
18. ⬜ **Página pública de catálogo y búsqueda** + vistas.

## Carrito: invitado

19. ⬜ **Modelos `Cart` y `CartItem`** + migración + factories + specs.
20. ⬜ **Controller de carrito** (añadir/quitar) + Turbo Frames.

## Carrito: registrado + fusión

21. ⬜ **Asociar carrito a `User`** + fusión del carrito de invitada al login.

## Pedidos: checkout y estados

22. ⬜ **Modelos `Order` y `OrderItem`** + máquina de estados del pedido con
    **AASM** (`pending → confirmed → shipped → delivered`, o `cancelled`) +
    migración + factories + specs.
23. ⬜ **Servicio de checkout** con transacción + spec.

## Pedidos: email y detalle

24. ⬜ **Mailer de confirmación de pedido** + job.
25. ⬜ **Detalle y listado de pedidos** del cliente + vistas.

## Métricas

26. ⬜ **Consultas/servicio de métricas** (ventas, productos, clientes) + specs.
27. ⬜ **Vista de métricas** para el panel.

## Panel de administración

28. ⬜ **Namespace `/admin`** + autorización por rol.
29. ⬜ **CRUDs de productos, pedidos y usuarios** en admin.

## Lanzamiento

30. ⬜ Seguridad, contenidos legales y pasarela de pago (con especificación propia).
