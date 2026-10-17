# Silvalde Web

Aplicación web profesional para una pequeña tienda de decoración. El objetivo es
permitir la venta online de productos y dejar una base preparada para crecer sin
perder control sobre la experiencia de compra ni sobre la operación interna.

## Alcance inicial

- Catálogo de productos de decoración con imágenes, variantes y disponibilidad.
- Navegación por categorías y búsqueda.
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

1. Copia o revisa las variables de [`.env.example`](./.env.example) y crea un
   `.env` local con valores seguros.
2. Arranca MySQL:

   ```bash
   docker compose up -d db
   ```

3. Instala dependencias y prepara la base de datos:

   ```bash
   bin/setup
   ```

4. Arranca la aplicación:

   ```bash
   bin/dev
   ```

Los comandos de validación y las convenciones de implementación están definidos
en [`AGENTS.md`](./AGENTS.md). Las directrices ampliadas están en
[`AGENTS.full.md`](./AGENTS.full.md). Los agentes deben leer `AGENTS.md` antes
de modificar código y consultar la versión completa cuando la tarea afecte a
arquitectura, seguridad, datos o UX.

## Estado y versionado

El proyecto está en desarrollo temprano: la autenticación (usuarios y
sesiones) se construye por slices sobre la base de Rails 8.1. La versión
publicada actual es **0.1.0** (la **0.2.0**, «autenticación y usuarios», está
en curso); la fuente única de verdad es el archivo
[`VERSION`](./VERSION) y el historial de cambios vive en
[`CHANGELOG.md`](./CHANGELOG.md).

El desarrollo se organiza en ramas por funcionalidad (`feat/authentication`,
`feat/catalog`, …) que se fusionan en `main` con el CI en verde.
Las fases previstas están en [`docs/roadmap.md`](./docs/roadmap.md) y la
convención completa de ramas y releases en [`AGENTS.md`](./AGENTS.md).

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
