# Roadmap de Silvalde Web

Plan de fases orientativo y referencia de control del proyecto. Cada fase
terminada e integrada en `main` publica una versión (ver
[versioning.md](./versioning.md)). Este documento se actualiza conforme avanza
el proyecto.

Leyenda: ✅ hecho · 🚧 en curso · ⬜ pendiente

## Fases

### 🚧 v0.1.0 — Base del proyecto

- Estructura Rails 8.1, documentación del proyecto y de agentes, versionado y
  flujo de trabajo con git.

### ⬜ v0.2.0 — Autenticación y usuarios

- Modelo `User` con el generador de autenticación de Rails 8.
- Registro, inicio/cierre de sesión y recuperación de contraseña.
- Roles básicos (`customer`, `admin`) y perfil de cliente.
- Consentimiento de comunicaciones comerciales (ofertas/rebajas futuras).

### ⬜ v0.3.0 — Catálogo

- Categorías y productos con variantes, imágenes (Active Storage) y
  disponibilidad.
- Navegación pública por categorías y búsqueda.

### ⬜ v0.4.0 — Carrito

- Carrito para visitantes y clientes registrados.
- Cantidades, variantes y persistencia al iniciar sesión.

### ⬜ v0.5.0 — Pedidos

- Checkout (sin pasarela de pago real de momento).
- Pedidos con estados definidos y detalle visible para el cliente.
- Emails transaccionales básicos (confirmación de pedido).

### ⬜ v0.6.0 — Panel de administración

- Autorización por rol aplicada en servidor.
- Gestión de usuarios, productos, pedidos y facturas.
- Métricas básicas y versión de la app visible en el footer del admin
  (`SilvaldeWebV2::APP_VERSION`).

### ⬜ v1.0.0 — Lanzamiento público

- Endurecimiento de seguridad, rendimiento y contenidos legales.
- Pasarela de pago y facturación fiscal (requieren especificación propia antes
  de implementarse).

## Notas

- Las fases pueden solaparse, pero no se integra nada a medias en `main`.
- Cualquier funcionalidad fuera de esta lista necesita antes su especificación
  (ver `AGENTS.full.md`, sección «Cambios y documentación»).
