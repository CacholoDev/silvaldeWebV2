# Silvalde Web

Aplicación web profesional para una pequeña tienda de decoración. El objetivo es
permitir la venta online de productos y dejar una base preparada para crecer sin
perder control sobre la experiencia de compra ni sobre la operación interna.

## Alcance inicial

- Catálogo de productos de decoración con imágenes, variantes y disponibilidad.
- Navegación por categorías y búsqueda.
- Landing pública como portada (`/`): presentación de la tienda, productos
  destacados, ofertas y galería de fotos. El login es opcional y nunca es la
  portada.
- Carrito y proceso de compra.
- Registro, inicio de sesión y gestión del perfil del cliente.
- Comunicación futura de ofertas y rebajas para usuarios registrados, siempre
  respetando el consentimiento y la normativa aplicable.
- Panel de administración para gestionar usuarios, productos, pedidos, facturas
  y métricas.

El alcance es evolutivo: cualquier funcionalidad nueva debe documentar su
motivación, límites y efecto sobre los flujos existentes antes de implementarse.

## Stack principal

- **Ruby 4.0.7**
- **Ruby on Rails 8.1**
- **MySQL 8.0**, ejecutado actualmente mediante Docker Compose.
- **Tailwind CSS** mediante `tailwindcss-rails`.
- **Hotwire** (Turbo y Stimulus) e **Importmap** para JavaScript.
- **JavaScript adicional** solo cuando Hotwire/Stimulus no resuelvan la necesidad.
- **Propshaft** para el pipeline de assets.
- **RSpec + FactoryBot** para los tests (system tests con Capybara/Selenium),
  según la configuración actual.

## Desarrollo local

Vale para cualquier PC nuevo: clona, configura `.env` y arranca.

1. Clona el repositorio y sitúate en la rama de trabajo:

   ```bash
   git clone https://github.com/CacholoDev/silvaldeWebV2.git
   cd silvaldeWebV2
   git switch feat/shopping-cart   # o la rama que toque en cada momento
   ```

2. Copia [`.env.example`](./.env.example) a `.env` y pon valores seguros
   (credenciales de MySQL locales; nunca lo subas al repositorio).
3. Arranca MySQL:

   ```bash
   docker compose up -d db
   ```

4. Instala dependencias y prepara la base de datos:

   ```bash
   bin/setup
   ```

5. Arranca la aplicación:

   ```bash
   bin/dev
   ```

Los comandos de validación y las convenciones de implementación están definidos
en [`AGENTS.md`](./AGENTS.md). Las directrices ampliadas están en
[`AGENTS.full.md`](./AGENTS.full.md). Los agentes deben leer `AGENTS.md` antes
de modificar código y consultar la versión completa cuando la tarea afecte a
arquitectura, seguridad, datos o UX.

## Estado y versionado

El proyecto está en desarrollo temprano. Publicadas: **0.1.0** (base del
proyecto), **0.2.0** («autenticación y usuarios») y **0.3.0** («catálogo»:
modelos, imágenes, seed, búsqueda y vistas públicas con accesibilidad y SEO).
La versión en desarrollo es la **0.4.0** («carrito»), en la rama
`feat/shopping-cart`: los modelos `Carts::Cart` y `Carts::CartItem` con sus
consultas en `Carts::Search` y la caducidad a los 6 meses ya están
terminados; quedan los services, la UI del carrito, la página `/cart`, la
fusión al login y la limpieza de carritos caducados. La fuente única de
verdad es el archivo [`VERSION`](./VERSION) y el historial de cambios vive
en [`CHANGELOG.md`](./CHANGELOG.md).

El desarrollo se organiza en ramas por funcionalidad (`feat/authentication`,
`feat/catalog`, `feat/shopping-cart`, …) que se fusionan en `main` con el CI
en verde. Las fases previstas están en [`docs/roadmap.md`](./docs/roadmap.md)
y la convención completa de ramas y releases en [`AGENTS.md`](./AGENTS.md).

## Documentación del proyecto

- [`docs/git-workflow.md`](./docs/git-workflow.md): ramas, commits y ciclo de
  una feature.
- [`docs/versioning.md`](./docs/versioning.md): cómo se versiona la web.
- [`docs/roadmap.md`](./docs/roadmap.md): fases previstas y control del avance.
- [`CHANGELOG.md`](./CHANGELOG.md): historial de cambios por versión.

## Variables de entorno y seguridad

Los secretos y credenciales se cargan desde `.env` en desarrollo y nunca deben
subirse al repositorio. No introduzcas contraseñas, claves, tokens ni datos
personales reales en código, fixtures, documentación o commits.

Antes de desplegar hay que configurar el correo: `APP_HOST` (dominio real
para los enlaces de los emails) y `MAILER_FROM` (remitente), además del SMTP.
Sin ellos, los emails de recuperación de contraseña no funcionan en
producción (ver `config/environments/production.rb` y `app/mailers/`).
