# Directrices para agentes

Estas reglas son obligatorias para cualquier agente (Claude Code, opencode,
Codex…) que trabaje en Silvalde Web. Lee este archivo antes de explorar o
editar el proyecto. La aplicación es una tienda online de decoración con
catálogo, clientes, pedidos y un panel de administración; el alcance puede
evolucionar, pero no se debe inventar producto o arquitectura fuera de la
tarea solicitada.

| Documento | Para qué |
| --- | --- |
| [`AGENTS.full.md`](./AGENTS.full.md) | Decisiones detalladas de arquitectura, stack, seguridad, datos, pruebas y UX (con fecha y riesgos aceptados). |
| [`README.md`](./README.md) | Contexto funcional y puesta en marcha en un PC nuevo. |
| [`docs/roadmap.md`](./docs/roadmap.md) | Fases del proyecto y **estado actual**. |
| [`CHANGELOG.md`](./CHANGELOG.md) | Historial de cambios; «Sin publicar» es lo que va en la próxima versión. |
| [`docs/git-workflow.md`](./docs/git-workflow.md) · [`docs/versioning.md`](./docs/versioning.md) | Ramas, commits y publicación de versiones. |
| [`docs/agent-tooling.md`](./docs/agent-tooling.md) | Skills, reviewer, permisos, cops y cómo tener todo igual en varios PCs. |

## Estado del proyecto

El estado vive en [`docs/roadmap.md`](./docs/roadmap.md) (fase en curso) y en
la sección «Sin publicar» de [`CHANGELOG.md`](./CHANGELOG.md); no se duplica
aquí para que no se quede desactualizado. Al empezar una sesión, léelos junto
con `git log --oneline -10` y `git status`.

Estructura que ya existe y debe reutilizarse: namespaces por dominio
(`Auth::`, `Users::`, `Catalog::`, `Carts::`), services en `app/services/`
(con un `search.rb` por dominio), decorators en `app/decorators/`
(`ApplicationDecorator` y los del catálogo y el carrito) y cops propios en
`lib/rubocop/cop/silvalde/`. No añadas estructura por adelantado.

## Cómo trabajamos (el usuario es junior y está aprendiendo)

Las explicaciones forman parte del trabajo. Estas reglas evitan implementar
demasiada superficie en una sesión y dejar al usuario sin contexto.

- **Mapa mental al inicio de cada sesión.** Muestra un mapa breve del estado:
  tablas, controllers, URLs, tests, rama actual y commits sin pushear. Si la
  sesión anterior dejó cambios sin commitear o sin pushear, avísalo al
  principio.
- **Explica el plan antes de implementar.** Resume en lenguaje sencillo qué vas
  a crear, qué herramientas de Rails usarás (generadores, migraciones, gemas…)
  y por qué.
- **Explica conceptos antes de preguntar opciones.** Si el usuario no puede
  evaluar una opción porque no conoce el concepto, explica primero y pregunta
  después. Si responde «no sé», propón la opción más sensata con su
  razonamiento y aplícala, avisando de lo que has elegido.
- **Vertical slices, no capas horizontales.** Una sesión de trabajo es una
  unidad pequeña y verificable a mano (p. ej. «modelo User con validaciones» o
  «signup end-to-end»); nada de modelo + controller + vista + mailer + jobs +
  tests de todo a la vez. Antes de cada slice: (a) explica en una frase qué
  entra y qué queda fuera, (b) di cómo se prueba a mano y (c) espera a que el
  usuario lo valide antes de continuar.
- **Sub-slices dentro del slice.** Un slice puede tener pasos internos (en
  `feat/user-model`: migración, modelo, validaciones, factory, test). Son
  unidades para mantener el orden; por defecto todos se commitean juntos al
  cerrar el slice, salvo que el usuario pida separarlos.
- **Cómo se cierra un slice, siempre en este orden:**
  1. **TDD**: primero el spec que fija el comportamiento, y se ve fallar
     (rojo); después el código mínimo que lo pone en verde, y por último se
     limpia (skill `test-driven-development`).
  2. **Validaciones**: `bin/rubocop` y los specs afectados (o `bin/ci`).
  3. **Propuesta de commit** (ver «Git, ramas, commits y versiones»).

  La review **no** es un paso automático: la lanza el usuario cuando quiere
  (normalmente al cerrar un slice) con `/project-review`. Si la pide, se hace
  antes del commit y sus hallazgos se corrigen o se documentan como riesgo
  aceptado en `AGENTS.full.md`.

## Git, ramas, commits y versiones

Flujo completo en [`docs/git-workflow.md`](./docs/git-workflow.md) y
[`docs/versioning.md`](./docs/versioning.md). Las reglas que no se negocian:

- **Ramas.** `main` es estable: siempre arranca y pasa las validaciones, y
  nunca se empieza una feature o un fix en ella. Al iniciar una tarea de
  código, comprueba la rama (`git branch --show-current`). Si estás en `main`
  o la tarea no encaja con la rama actual, **propón un nombre** (`feat/…`,
  `fix/…`, `chore/…`, `docs/…`; minúsculas, guiones, en inglés) y espera su
  OK antes de `git switch -c`; después confirma el nombre definitivo. Si el
  usuario dice que no sabe, aplica la regla de «no sé» de arriba.
- **Una rama por feature o fix, no por slice.** Los slices son commits dentro
  de la misma rama. Una rama = una responsabilidad.
- **Commits al cerrar un slice, no antes.** Con el slice terminado y
  verificado, propón el mensaje (Conventional Commits, `type`/`scope` y
  resumen en inglés e imperativo: `feat:`, `fix:`, `docs:`, `test:`,
  `refactor:`, `chore:`) y una lista corta de los archivos que entran. **No
  pegues el diff**: el usuario lo revisa en el panel Source Control de VS
  Code. Cualquier respuesta afirmativa vale como OK («dale», «ok», «venga»,
  «vamos», «sí», «perfecto», 👍…); interprétala por la intención, no por la
  palabra exacta. Si la respuesta es ambigua o pide cambios, pregunta o
  ajusta antes de commitear. Por defecto, un slice = un commit. Atajo: la
  skill `commit` (`/commit`).
- **Tests en el mismo commit que el código que prueban.** Nada de commits
  `test:` sueltos salvo para arreglar regresiones o cubrir código viejo.
- **Push, merge, tags y PRs.** El agente no hace commit, push, merge ni tags
  sin confirmación explícita. El push es una acción aparte: aunque el usuario
  haya aprobado el commit, espera un OK específico para el push. Un merge en
  `main` necesita su propia confirmación dedicada. **Abrir un PR también
  necesita el OK explícito del usuario**: que el trabajo esté terminado no lo
  autoriza. Con la rama lista, el agente dice qué commits tiene y pregunta
  «¿abro el PR?». (Claude
  Code y opencode lo refuerzan: piden confirmación para esos comandos, ver
  `docs/agent-tooling.md`.)
- **Versiones.** La versión vigente vive en [`VERSION`](./VERSION) (fuente
  única; la app la expone como `SilvaldeWebV2::APP_VERSION`) y el historial
  en `CHANGELOG.md`. SemVer en `0.x.y` hasta el lanzamiento público
  (`1.0.0`). No se sube la versión dentro de una rama `feat/*`.
- **Code review: la lanza el usuario**, nunca el agente por iniciativa
  propia. Se hace con la skill global `/project-review` (repo
  `agent-dotfiles`; en opencode, `@project-reviewer`) y el **perfil de silWeb**
  en `.claude/review/` (checklist, ejemplos reales y comprobaciones propias). Modos: `slice` (lo que no se ha commiteado), `rama` o `version`
  (desde el último tag).
  - Al cerrar una versión, antes de abrir su PR, el agente **recuerda** que
    toca la review de versión y espera a que el usuario la lance.
  - Los hallazgos se corrigen, o se documentan como riesgo aceptado en
    `AGENTS.full.md`, antes del commit o del PR.
- Al completar una fase, actualiza [`docs/roadmap.md`](./docs/roadmap.md).

## Reglas de trabajo

- Inspecciona el código existente antes de crear archivos o abstracciones.
- Haz cambios pequeños, explícitos y coherentes con Rails.
- **Inglés en el código, español con el usuario.** En inglés: ramas,
  identificadores (clases, métodos, variables, columnas), migraciones,
  mensajes de commit y contenido de los PRs. En español: documentación,
  comentarios extensos y la conversación con el usuario. Detalle en
  `AGENTS.full.md`, «Idioma de código y documentación».
- **i18n obligatoria desde el inicio.** Español (por defecto), gallego e
  inglés (`config.i18n.available_locales`); el idioma lo elige la usuaria con
  un selector visible en la UI. Nada de cadenas hardcodeadas en vistas,
  mailers ni controllers: **toda clave nueva va en los tres**
  `config/locales/{es,gl,en}.yml` (lo comprueban `spec/i18n` y el barrido de
  `/project-review`). El contenido del catálogo (nombres y descripciones de
  productos) está solo en español. No
  se deduce el idioma de la URL ni de `Accept-Language` hasta que se defina.
- **No toques tests existentes para ocultar un fallo.** Corrige el código de
  producción o añade cobertura. Si un contrato cambia de verdad (p. ej. una
  consulta que se mueve a un `Search`), las aserciones se mueven con él sin
  perder cobertura, y se explica en el resumen.
- No añadas gemas, servicios externos o patrones nuevos sin justificar su
  necesidad y actualizar la documentación relacionada.
- No pongas secretos ni datos de clientes en el repositorio.
- No uses `rescue` amplio ni devuelvas falsos éxitos: los errores inesperados
  se propagan y quedan visibles en logs.
- **Reset de BD permitido fuera de producción.** En local se puede borrar y
  recrear la base de datos cuando rehacer es más limpio que migrar
  (`docker compose down -v db && docker compose up -d db && bin/rails
  db:prepare`). En staging y producción está prohibido hasta que exista un
  proceso de migraciones aprobado.
- La documentación es parte del producto: `AGENTS.md`, `AGENTS.full.md`,
  `README.md`, `CHANGELOG.md` y `docs/` se actualizan en la misma rama que el
  cambio que los motiva (comportamiento, contrato o flujo de desarrollo).

## Stack y límites

- Ruby 4.0.7, Rails 8.1 y MySQL 8.0 (Docker Compose o Podman en desarrollo).
- Tailwind CSS para estilos; Turbo/Stimulus e Importmap para interacción.
  JavaScript adicional solo cuando Hotwire no baste.
- RSpec + FactoryBot: specs en `spec/`, factories en `spec/factories/`. Los
  system specs (`spec/system/`) usan Capybara con Chrome headless. Minitest
  solo con una excepción justificada.
- Autenticación nativa de Rails 8 y sesiones con cookie firmada (no Devise ni
  JWT). Solid Queue/Cache sobre MySQL (no Redis ni Sidekiq); jobs vía Active
  Job.
- Web HTML con Hotwire: no hay API pública, así que nada de Grape, Swagger,
  JWT ni Jbuilder. Si aparece la necesidad de una API, se especifica aparte.
- Nunca `rails generate scaffold`. Generadores pequeños (`model`,
  `migration`) como punto de partida; controllers, services, decorators y
  vistas se escriben a mano. Detalle en `AGENTS.full.md`, «Decisiones de
  stack».

## Comandos

```bash
docker compose up -d db   # MySQL 8.0; obligatorio antes de test/dev (o podman-compose up -d db)
bin/setup                 # dependencias + db:prepare
bin/dev                   # Puma + tailwindcss:watch (no uses `rails s` a secas)
bundle exec rspec         # todos los specs, incluidos system specs y los de los cops
bin/ci                    # CI local completo: setup, rubocop, audits, brakeman, tests, seeds
```

Validaciones individuales: `bin/rubocop` (incluye los cops `Silvalde/*`),
`bin/brakeman`, `bin/bundler-audit` y `bin/importmap audit`. GitHub Actions
ejecuta todo eso en cada PR. Antes de dar una tarea por terminada corre
`bin/ci`, o como mínimo rubocop y los specs afectados. Si una herramienta no
está disponible, dilo y ejecuta el resto. No marques nada como verificado sin
indicar qué se ejecutó y su resultado.

La app lee la base de datos de `.env` (`DB_HOST`, `DB_PORT`, `MYSQL_USER`,
`MYSQL_PASSWORD`; contrato en `.env.example`). Sin `.env` fallan el arranque y
los tests. Si el puerto 3306 está ocupado (otro MySQL), usa `DB_PORT=3307`.

## Arquitectura obligatoria

MVC con **services** y **decorators**. Las dos primeras reglas las vigila
RuboCop (`Silvalde/NoActiveRecordInControllers` y
`Silvalde/NoQueriesInModels`), así que `bin/rubocop` falla si se rompen.

- **Controllers**: orquestan `authorize → service → respond`. Sin reglas de
  negocio ni acceso directo a la base de datos: nada de `Model.find`,
  `Model.create`, `Model.where`, `authenticate_by`… Las lecturas van a
  `app/services/<contexto>/search.rb` y las escrituras a services de caso de
  uso. Construir un objeto vacío para un formulario (`Users::User.new`) sí
  está permitido. Excepción: la infraestructura de sesión (concern
  `Authentication`).
- **Lecturas, siempre por el `Search` del dominio**, también desde un
  service de caso de uso. Ni `Model.where`/`find_by` en un service, ni
  `Model.scope_x` (los scopes no existen, ver Models). Ejemplo: no
  `PasswordResetToken.active.find_by(...)`, sino
  `Auth::Search.active_password_reset_tokens.find_by(...)`. El cop solo vigila
  controllers y models, así que en services esto lo comprueba la review.
- **Models**: asociaciones, validaciones, invariantes y comportamiento propio
  de la entidad (**métodos sin parámetros** sobre su propio estado:
  `available?`, `expired?`). **Nunca consultas**: ni `where`, ni `find_by`, ni
  scopes ni `default_scope`. El nombre para i18n y formularios lo resuelve
  `ApplicationRecord`, no cada modelo. Delgados.
- **Services**: un caso de uso por service, una sola responsabilidad
  (`app/services/<contexto>/<caso_de_uso>.rb`). Toda operación que toque
  varios modelos o tenga reglas de negocio va aquí, con transacción cuando
  modifique varias tablas, y falla explícitamente ante errores inesperados.
- **Decorators**: presentación y formato para las vistas; no mutan ni
  esconden consultas.
- **Views/partials**: presentan datos; sin reglas de negocio.

Usa `has_many :through` con modelo intermedio cuando una relación tenga datos
o reglas propias. No introduzcas una máquina de estados sin definir estados,
transiciones válidas y cómo se muestran al usuario.

## Flujo obligatorio de una tarea

1. Lee `README.md`, este archivo y, si aplica, `AGENTS.full.md`.
2. Identifica rutas, modelos, services, vistas y tests afectados.
3. Implementa la solución mínima completa siguiendo las convenciones Rails
   (con TDD: primero el spec que fija el comportamiento).
4. Añade o actualiza tests de comportamiento sin alterar los existentes.
5. Ejecuta las validaciones relevantes y repasa el diff antes de terminar.

## Skills y herramientas

Detalle, instalación y sincronización entre PCs en
[`docs/agent-tooling.md`](./docs/agent-tooling.md).

- **Skills del proyecto** (versionadas en git): `.claude/skills/`, las
  propias de silWeb, como `commit`. Las leen tanto Claude Code como opencode.
- **Perfil de review** (versionado): `.claude/review/` — `rules.md`,
  `examples.md` y `checks.tsv`, que usa `/project-review`.
- **Skills de terceros** (globales, desde el repo `agent-dotfiles`):
  `frontend-design`, `accessibility`, `seo-audit`, `tailwind-animations`,
  `find-docs`, `rails-test-coverage` (qué tests faltan según lo crítico),
  `rails-architecture-review` (blueprint antes de decisiones delicadas como el
  checkout)… Están instaladas en todos tus PCs, así que no van en este repo.

  Antes de empezar una tarea, revisa las skills disponibles y carga las que
  apliquen.
- **Superpowers** (plugin global): el propio plugin indica al agente cuándo
  cargar cada skill de proceso. En este proyecto se usan sobre todo
  `brainstorming` (antes de una feature o cambio de comportamiento),
  `systematic-debugging` (ante un bug o test en rojo), `test-driven-development`,
  `writing-plans`/`executing-plans` (tareas multi-paso) y
  `verification-before-completion` (antes de afirmar que algo está en verde).
  Para el code review se usa `/project-review` (ver abajo) en lugar de
  `requesting-code-review`, y solo cuando el usuario lo pide.
- **`/project-review`** (skill global, repo `agent-dotfiles`): la review, con
  el perfil de `.claude/review/`. Se ejecuta en el subagente global
  `project-reviewer`, que es de solo lectura.

Si el archivo de directrices crece demasiado, mueve temas a `docs/` y
enlázalos desde aquí, pero mantén en este archivo las reglas críticas para que
se vean en la primera carga.
