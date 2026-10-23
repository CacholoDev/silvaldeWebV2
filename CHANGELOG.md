# Changelog

Todos los cambios destacables de Silvalde Web se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y el versionado sigue [SemVer](https://semver.org/lang/es/). La versión
vigente está en el archivo `VERSION` y el proceso de publicación en
`docs/versioning.md`.

Tipos de cambio: `Añadido`, `Cambiado`, `Obsoleto`, `Eliminado`,
`Corregido`, `Seguridad`.

## [Sin publicar]

### Añadido

- Decisiones de stack documentadas en `AGENTS.full.md`: autenticación nativa
  de Rails 8 (no Devise), sesiones con cookie (no JWT), Solid Queue/Cache (no
  Redis/Sidekiq), RSpec + FactoryBot (no Minitest), web HTML sin API pública
  (no Grape/Swagger), política de generadores (sin `scaffold`) y Pundit como
  candidato futuro para el panel admin.

- `docs/roadmap.md`: definición clara de la primera versión de la web
  (qué podrá hacer la clienta, qué el panel admin y qué queda fuera) y
  explicación del enfoque técnico de cada fase.
- `AGENTS.md`: nuevas reglas — los agentes deben explicar el plan antes de
  implementar (usuario junior) y crear la rama de trabajo antes de escribir
  código, avisando al usuario.
- Decisión de stack: **AASM** para la máquina de estados de los pedidos
  (`Order`), con estados `pending → confirmed → shipped → delivered` (o
  `cancelled`). Documentado en `AGENTS.full.md`, `docs/roadmap.md` y
  `docs/backend-plan.md`.
- Principio de producto: la web es pública y el registro es opcional — la
  visitante ve la landing/catálogo, no el login (documentado en
  `AGENTS.full.md`).
- `docs/backend-plan.md`: desglose del backend en slices, con los grupos
  renombrados para no colisionar con las versiones del roadmap.
- Autenticación (slice 4): rutas de login/logout (`/login`, `/logout`),
  controlador `SessionsController` con request spec, y un `root` provisional
  (`HomeController`) que luego será la landing del catálogo. Resuelve el spec
  que esperaba `login_path`.
- Autenticación (slice 5): registro (signup) — rutas `/signup`, controlador
  `UsersController`, service `Users::Register` y request spec. La usuaria
  queda logueada automáticamente tras registrarse.
- Refactor de autenticación: lógica de login/signup extraída a services
  (`Users::Authenticate` y `Users::Register`). Nueva regla en `AGENTS.md` y
  `AGENTS.full.md`: los controllers no consultan ni escriben en la base de
  datos; esa interacción vive en services.
- Autenticación (slice 6): vistas de login/signup con Tailwind, navegación
  global (navbar con estado de sesión) y selector de idioma (español/inglés)
  persistido en cookie.
- Autenticación (slice 7): recuperación de contraseña (parte 1) — rutas
  `/password/reset`, controlador `PasswordsController`, service
  `Passwords::RequestReset`, mailer `PasswordsMailer` y envío async
  (`deliver_later`). La usuaria pide el reset y recibe un enlace por email;
  sin revelar si el email existe o no.
- Autenticación (slice 8): recuperación de contraseña (parte 2) — vistas y
  acciones `edit`/`update` para poner la nueva contraseña, service
  `Passwords::Reset`. El token pasa de BCrypt a SHA256 (como las sesiones)
  para poder buscarlo por el enlace.

### Corregido

- Concern `Authentication`: renombrado `user_signed_in` a `user_signed_in?`
  para que coincida con el `helper_method` y funcione en las vistas (detectado
  al añadir la navegación).

## [0.1.0] - 2026-10-11

### Añadido

- Scaffold inicial de Rails 8.1 con Ruby 4.0.7, MySQL 8.0 (Docker Compose),
  Tailwind CSS, Hotwire (Turbo/Stimulus) e Importmap.
- Documentación base del proyecto y de agentes: `README.md`, `AGENTS.md` y
  `AGENTS.full.md`.
- Control de versiones: SemVer, archivo `VERSION` como fuente única de verdad
  (expuesta en la app como `SilvaldeWebV2::APP_VERSION`), este changelog y
  proceso de publicación en `docs/versioning.md`.
- Flujo de trabajo por ramas y Conventional Commits en
  `docs/git-workflow.md`, y plan de fases en `docs/roadmap.md`.

[Sin publicar]: https://github.com/CacholoDev/silvaldeWebV2/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/CacholoDev/silvaldeWebV2/releases/tag/v0.1.0
