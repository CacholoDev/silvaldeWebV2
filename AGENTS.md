# Directrices para agentes

Estas reglas son obligatorias para cualquier agente que trabaje en Silvalde Web.
Lee este archivo antes de explorar o editar el proyecto. La aplicación es una
tienda online de decoración con catálogo, clientes, pedidos y un panel de
administración; el alcance puede evolucionar, pero no se debe inventar producto
o arquitectura fuera de la tarea solicitada.

Para decisiones detalladas de arquitectura, seguridad, datos, pruebas y UX,
consulta [`AGENTS.full.md`](./AGENTS.full.md). Para el contexto funcional,
consulta [`README.md`](./README.md). El historial de cambios vive en
[`CHANGELOG.md`](./CHANGELOG.md).

## Estado del proyecto

Greenfield: scaffold de Rails 8.1 sin modelos, rutas ni migraciones de dominio
(solo las tablas internas de solid_cache, solid_queue y solid_cable).
`app/services` y `app/decorators` aún no existen: créalos cuando el primer
caso de uso los necesite, aplicando la arquitectura obligatoria de abajo. No
añadas estructura por adelantado.

## Reglas de trabajo

- Inspecciona el código existente antes de crear archivos o abstracciones.
- Haz cambios pequeños, explícitos y coherentes con Rails.
- No modifiques ni elimines tests existentes para ocultar un fallo; corrige el
  código de producción o añade cobertura cuando corresponda.
- No añadas gemas, servicios externos o patrones nuevos sin justificar su
  necesidad y actualizar la documentación relacionada.
- No pongas secretos ni datos de clientes en el repositorio.
- No uses `rescue` amplio ni devuelvas falsos éxitos: los errores inesperados
  deben propagarse y quedar visibles en logs.
- Actualiza el README o la documentación ampliada si cambia el comportamiento,
  el contrato de una API o el flujo de desarrollo.

## Stack y límites

- Ruby 4.0.7, Rails 8.1 y MySQL 8.0 (Docker Compose en desarrollo).
- Tailwind CSS para estilos; Turbo/Stimulus e Importmap para interacción.
  Usa JavaScript adicional solo cuando sea necesario.
- Minitest (con Capybara/Selenium para system tests). Usa el estilo ya
  presente antes de introducir otra herramienta.

## Comandos

```bash
docker compose up -d db   # MySQL 8.0; obligatorio antes de test/dev
bin/setup                 # dependencias + db:prepare
bin/dev                   # Puma + tailwindcss:watch (no uses `rails s` a secas)
bin/rails test            # Minitest (requiere MySQL arrancado)
bin/rails test:system     # system tests (job aparte en CI, opt-in en local)
bin/ci                    # CI local completo: setup, rubocop, audits, brakeman, test, seeds
```

Validaciones individuales: `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit`,
`bin/importmap audit`. GitHub Actions ejecuta todo eso en cada PR; corre
`bin/ci`, o como mínimo rubocop y los tests afectados, antes de dar una tarea
por terminada. Si una herramienta no está disponible, infórmalo y ejecuta el
resto. No marques una tarea como verificada sin indicar qué se ejecutó.

La app lee las credenciales de base de datos de `.env` (`DB_HOST`, `DB_PORT`,
`MYSQL_USER`, `MYSQL_PASSWORD`; contrato en `.env.example`). Sin `.env` fallan
el arranque y los tests.

## Arquitectura obligatoria

Usa MVC con **servicios** y **decorators**:

- **Controllers**: orquestan la petición, autorización, servicio y respuesta.
  No contienen reglas de negocio ni consultas Active Record complejas.
- **Models**: contienen asociaciones, validaciones, invariantes y comportamiento
  propio de la entidad. Deben mantenerse delgados.
- **Services**: encapsulan casos de uso y operaciones con varios modelos. Cada
  servicio tiene una responsabilidad clara y debe fallar explícitamente ante
  errores inesperados.
- **Decorators**: preparan presentación y formato para las vistas; no deben
  ejecutar mutaciones ni esconder consultas.
- **Views/components**: presentan datos y usan helpers/componentes reutilizables;
  no implementan reglas de negocio.

Prioriza transacciones para operaciones que afecten a varias entidades. Usa
`has_many :through` con modelo intermedio cuando una relación tenga datos o
reglas propias. No introduzcas una máquina de estados sin definir estados,
transiciones válidas y cómo se muestran al usuario.

## Flujo obligatorio

1. Lee `README.md`, este archivo y, si aplica, `AGENTS.full.md`.
2. Identifica rutas, modelos, servicios, vistas y tests afectados.
3. Implementa la solución mínima completa, manteniendo las convenciones Rails.
4. Añade o actualiza tests de comportamiento sin alterar tests existentes.
5. Ejecuta las validaciones relevantes y revisa el diff antes de terminar.

## Git, ramas y versiones

- `main` es la rama estable: siempre debe arrancar y pasar las validaciones.
  El trabajo se hace en ramas (`feature/<nombre>`, `fix/<nombre>`,
  `chore/<nombre>`, `docs/<nombre>`; minúsculas, guiones, en español) que se
  integran en `main` con `bin/ci` en verde. Una rama = una responsabilidad.
  Flujo completo: [`docs/git-workflow.md`](./docs/git-workflow.md).
- Los commits siguen Conventional Commits en español e imperativo
  (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`).
- La versión vigente vive en el archivo [`VERSION`](./VERSION) (fuente única
  de verdad; la app la expone como `SilvaldeWebV2::APP_VERSION`) y su
  historial en [`CHANGELOG.md`](./CHANGELOG.md). SemVer: estamos en `0.x.y`
  hasta el lanzamiento público, que será `1.0.0`. No subas la versión dentro
  de una rama `feature/*`. Proceso de publicación:
  [`docs/versioning.md`](./docs/versioning.md).
- Las fases del proyecto y su estado están en
  [`docs/roadmap.md`](./docs/roadmap.md); actualízalo al completar una fase.
- Los agentes no hacen commits, merges, push ni tags sin confirmación
  explícita del usuario.

## Documentación

La documentación extensa vive en [`AGENTS.full.md`](./AGENTS.full.md). Si ese
archivo crece demasiado, divide los temas en `docs/` y enlázalos desde ambos
archivos de directrices. Mantén siempre estas reglas críticas en este archivo
para que sean visibles en la primera carga del agente.

`AGENTS.md`, `AGENTS.full.md`, `README.md`, `CHANGELOG.md` y `docs/` están
versionados en git junto al código: la documentación es parte del producto y
debe actualizarse en la misma rama que el cambio que la motiva.
