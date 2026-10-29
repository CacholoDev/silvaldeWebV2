# Changelog

Todos los cambios destacables de Silvalde Web se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y el versionado sigue [SemVer](https://semver.org/lang/es/). La versión
vigente está en el archivo `VERSION` y el proceso de publicación en
`docs/versioning.md`.

Tipos de cambio: `Añadido`, `Cambiado`, `Obsoleto`, `Eliminado`,
`Corregido`, `Seguridad`.

## [Sin publicar]

### Seguridad

- Recuperación de contraseña endurecida: un reset exitoso revoca todas las
  sesiones del usuario y consume todos sus tokens pendientes en una sola
  transacción (el consumo del token es atómico, así dos envíos simultáneos
  del mismo enlace no pueden ganar los dos); pedir un nuevo enlace invalida
  los anteriores. Una cookie robada deja de funcionar tras el reset.
- El token de reset viaja ahora como parámetro de consulta (no en la ruta de
  la URL) para que no se filtre en los logs del servidor: Rails lo registra
  como `[FILTERED]`.
- Longitud mínima de contraseña de 8 caracteres.

### Corregido

- Traducciones de validación faltantes (`password_too_long` y `confirmation`):
  en español se mostraba «Translation missing...» al fallar la confirmación
  de contraseña o con contraseñas demasiado largas. Además, `errors.format`
  hace que los mensajes de error se lean completos (sin el nombre del campo
  duplicado al principio).
- El CI de GitHub ejecutaba la suite de Minitest (0 tests) en vez de RSpec:
  ahora crea el `.env` del workflow, corre `bundle exec rspec` y los seeds,
  y se elimina el job muerto de system tests.
- Las consultas de lectura de auth viven ahora en `Auth::Search`
  (`find_user_by_email`, `authenticate`), como manda la convención
  `search.rb`.
- El host y el remitente del mailer se configuran por variables de entorno
  (`APP_HOST`, `MAILER_FROM`): antes apuntaban a `example.com` y los emails
  de recuperación no habrían funcionado en producción.
- La suite de specs purga los datos demo al arrancar (`bin/ci` deja los
  seeds en la BD de tests y rompía los specs que asumen un catálogo limpio).

### Añadido

- Catálogo (slices 1-3 de v0.3.0): modelos `Catalog::Category`,
  `Catalog::Product` y `Catalog::Variant` con migraciones, índices únicos,
  claves foráneas, factories y specs de modelo. Decisiones de datos
  documentadas en `AGENTS.full.md`: namespace `Catalog::` con tablas sin
  prefijo, precios en céntimos (`price_cents`, euros fijos) con validación
  numérica estricta (entero, no negativo), slug automático desde el nombre
  con `parameterize`, disponibilidad = stock de la variante (`stock > 0`) y
  variante obligatoria para la venta (un producto sin variantes es un
  borrador no disponible; los artículos únicos llevan una variante «Única»).
  Una categoría con productos no se puede borrar (`restrict_with_exception`)
  y un producto borra sus variantes al borrarse (`dependent: :destroy`).
- Traducciones de validaciones (es/en) para los modelos del catálogo en
  `config/locales/{es,en}.yml`.
- Imágenes de producto (slice 4 de v0.3.0): Active Storage en
  `Catalog::Product` (`has_many_attached :images`) con validaciones de tipo
  (JPEG/PNG/WebP), tamaño (5 MB por imagen) y cantidad (10 por producto),
  specs con fixtures reales en `spec/fixtures/files/images/` y fotos demo de
  ejemplo en `db/seeds/images/`.
- Seed de demostración (slice 5 de v0.3.0): `db/seeds.rb` con 4 categorías,
  8 productos y 13 variantes de ejemplo (incluye variantes sin stock y con
  precio que sobrescribe al del producto), fotos demo adjuntas y specs que
  verifican que el seed es idempotente.
- Búsqueda del catálogo (slice 6 de v0.3.0): service `Catalog::Search` con
  las consultas de lectura del dominio — búsqueda por nombre/descripción
  tolerante a mayúsculas, acentos y caracteres comodín, productos por
  categoría y lookup por slug con las variantes precargadas — con specs.
- Vistas públicas del catálogo, parte de back (slice 18a de v0.3.0): rutas
  públicas `/`, `/products`, `/products/:slug` y `/categories/:slug` (la
  búsqueda usa `/products?q=`), controllers del dominio `Catalog::` que
  delegan en `Catalog::Search`, decorators de presentación en
  `app/decorators` (formato de precio y disponibilidad) y vistas
  funcionales con i18n + request specs. La home provisional se sustituye
  por la landing.
- Vistas públicas del catálogo, parte de front (slice 18b de v0.3.0):
  diseño de la landing (hero, rail de categorías, destacados, ofertas y
  galería de fotos en acordeón), tarjetas de producto, detalle a dos
  columnas, pie de página con enlaces internos y el enlace al catálogo en la
  navegación. Accesibilidad (WCAG 2.2 AA): enlace de salto al contenido,
  landmarks, un único `h1` por página, jerarquía de encabezados, textos
  alternativos en las fotos, etiquetas de formulario, foco visible,
  objetivos táctiles de 44 px y respeto de `prefers-reduced-motion`; los
  bordes de los controles de formulario usan un tono con contraste 3:1.
  SEO en página: título y meta descripción únicos por página, URL
  canónica, etiquetas Open Graph, datos estructurados `Product` (JSON-LD),
  `sitemap.xml` y `robots.txt` con la referencia al sitemap.
- Modo claro/oscuro con botón sol/luna: el tema se aplica con una clase
  `dark` en `<html>` y las variables CSS semánticas (`--paper`, `--ink`,
  `--muted`, `--line`…) cambian de valor, así que un solo botón oscurece
  toda la web. La preferencia se guarda en `localStorage` y se aplica antes
  de pintar la página (`app/javascript/theme.js`, cargado en el `<head>`)
  para evitar el parpadeo del tema. **Modo claro por defecto.**
- Selector de idioma desplegable con icono de globo: se abre al pasar el
  ratón o con el teclado, se cierra con Escape, click fuera o al salir.
- Pie de página compacto con los datos de contacto de la tienda (correo,
  dos teléfonos y redes sociales) tomados de `app/lib/shop.rb`, en lugar de
  cadenas fijas en la vista.
- PWA activada: rutas de `manifest.json` y `service-worker.js`, enlace al
  manifest en el layout y `short_name` en el manifest.
- Iconos de marca reorganizados en `public/icons/` y `public/svg/`, con
  versión en la URL (`?v=`) para que el navegador no sirva un logo
  antiguo cacheado.

### Cambiado

- Nueva regla de proceso (`AGENTS.md`, `AGENTS.full.md`, `docs/versioning.md`):
  el code review de superpowers (`requesting-code-review` /
  `receiving-code-review`) se pasa **al final de cada versión y antes de su
  PR**, nunca por slice (porque ralentiza el flujo).
- Documentación actualizada al estado real del proyecto (pendiente desde
  v0.2.0): `AGENTS.md` (estado del proyecto), `README.md` (estado y landing
  como portada), `AGENTS.full.md` (landing con productos, ofertas y galería
  de fotos; login opcional; decisiones de datos del catálogo; el stock solo se
  modifica en transacciones con bloqueo de fila), `docs/backend-plan.md`
  (slices del catálogo reordenados: modelos → imágenes → seed → búsqueda →
  vistas) y `docs/roadmap.md` (v0.3.0 en curso).

## [0.2.0] - 2026-10-24

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
- Autenticación (slice 9): columna `role` en `User` (enum `customer`/`admin`,
  por defecto `customer`) + migración.
- Autenticación (slice 10): perfil del cliente — controller
  `Users::ProfilesController` (ver/editar, protegido con
  `require_authentication`), service `Users::UpdateProfile` y enlace "Perfil"
  en el navbar.
- Autenticación (slice 11): consentimiento de comunicaciones — columna
  `communications_consent` (booleana, por defecto `false`) + checkbox en el
  registro y el perfil (revocable).

### Cambiado

- Refactor de organización: el código de autenticación se agrupa por dominio en
  namespaces (`Auth::` y `Users::`); controllers, models y services dejan de
  estar en la raíz. Las consultas se mueven a services de búsqueda
  (`Auth::Search`, patrón `search.rb`), sacándolas de models y controllers.
  Documentado en `AGENTS.md` y `AGENTS.full.md`.

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

[Sin publicar]: https://github.com/CacholoDev/silvaldeWebV2/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/CacholoDev/silvaldeWebV2/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/CacholoDev/silvaldeWebV2/releases/tag/v0.1.0
