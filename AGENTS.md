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
- **Commits al cerrar un slice, no antes.** Cuando un slice está
  terminado y verificado a mano, el agente propone un mensaje de commit
  en inglés (Conventional Commits) y espera a que el usuario confirme.
  El usuario puede decir "haz commit", pedir cambios al mensaje, o pedir
  partir el slice en dos commits. Por defecto, un slice = un commit.
  Antes de ejecutar `git commit`, el agente muestra el `git diff
  --staged` o `git status` para que el usuario vea exactamente qué
  entra, y espera un OK literal ("haz commit"). Instrucciones generales
  como "arranca ya", "vamos" o "tira" **no** cuentan como confirmación
  de commit: el agente debe pedir ese OK explícito antes de ejecutar
  `git commit`.
- **Tests en el mismo commit que el código.** Los tests del slice se
  commitean junto con el código que prueban, en el mismo commit, para
  que el historial refleje qué se probó junto con qué. No se hacen
  commits `test:` sueltos salvo para arreglar regresiones o cubrir
  código viejo. En este proyecto los tests son specs de RSpec y viven
  en `spec/`.
- **Internacionalización (i18n) obligatoria desde el inicio.** La app
  debe estar preparada para español e inglés, y el idioma lo elige la
  usuaria desde la UI (un selector visible). Nada de cadenas
  hardcodeadas en vistas, mailers ni controladores: todo va en
  `config/locales/{es,en}.yml`. La detección inicial se delega a la
  UI; no se deduce automáticamente de la URL ni de `Accept-Language`
  hasta que se defina explícitamente.
- **Services obligatorios para lógica que cruza modelos o casos de uso.**
  Cualquier operación que toque varios modelos o tenga reglas de
  negocio va en `app/services/<contexto>/<caso_de_uso>.rb`. Los
  controllers orquestan (`authorize → service → respond`): **no consultan
  ni escriben en la base de datos directamente** (nada de `Model.find`,
  `Model.create`, `Model.where`, `authenticate_by`, …); toda interacción
  con ActiveRecord vive en services o en métodos del modelo. Cada service
  hace una única cosa (una sola responsabilidad). Consultar
  `AGENTS.full.md` para detalles de la arquitectura services/decorators.
- **Reset de BD permitido fuera de producción.** Mientras el entorno
  no sea el de producción, está permitido borrar y recrear la base de
  datos para alinearla con los cambios del slice (por ejemplo, cuando
  rehacer desde cero es más limpio que migrar incrementalmente). En
  desarrollo local: `docker compose down -v db && docker compose up -d
  db && bin/rails db:create db:schema:load` (o `db:migrate` si se
  prefiere). En staging y producción queda prohibido hasta que se
  defina un proceso de migraciones explícito y aprobado.
- **Explica el plan antes de implementar**: al empezar una feature o fix,
  resume al usuario en lenguaje sencillo qué vas a crear, qué herramientas de
  Rails usarás (generadores, migraciones, gemas…) y por qué. El usuario es
  junior y está aprendiendo: las explicaciones forman parte del trabajo.
- **Crea la rama antes de codificar**: al iniciar cualquier tarea de código,
  comprueba la rama actual (`git branch --show-current`). Si es `main`, crea
  primero la rama `feat/…`, `fix/…`, `chore/…` o `docs/…` que corresponda
  y avisa al usuario de la rama creada. Nunca empieces una feature o fix en
  `main` (ver «Git, ramas y versiones»). El nombre de la rama va en inglés.
- **Código y ramas en inglés**: los nombres de ramas, los identificadores de
  código (clases, métodos, variables), los mensajes de commit (type, scope y
  resumen) y el contenido de los PRs se escriben **en inglés**. La
  documentación, los comentarios extensos, los mensajes al usuario y los
  commits narrativos en español se mantienen en español. Mantén el español
  para explicar al usuario junior, no para el código.
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
- RSpec + FactoryBot (con Capybara/Selenium para system tests). El
  proyecto usa RSpec como framework de tests y FactoryBot para generar
  datos de prueba. Los specs viven en `spec/`; los factories en
  `spec/factories/`. Si necesitas Minitest, abre una excepción y
  justifícala.
- Autenticación nativa de Rails 8 y sesiones con cookie firmada (no Devise ni
  JWT). Solid Queue/Cache sobre MySQL (no Redis ni Sidekiq); jobs vía
  `Active Job`.
- Web HTML con Hotwire: no hay API pública, así que nada de Grape, Swagger ni
  JWT. Si aparece la necesidad de una API, se especifica aparte.
- Nunca `rails generate scaffold`. Generadores pequeños (`model`,
  `migration`) como punto de partida; controllers, servicios, decorators y
  vistas se escriben a mano. Detalle y excepciones en `AGENTS.full.md`,
  sección «Decisiones de stack».

## Comandos

```bash
docker compose up -d db   # MySQL 8.0; obligatorio antes de test/dev
bin/setup                 # dependencias + db:prepare
bin/dev                   # Puma + tailwindcss:watch (no uses `rails s` a secas)
bundle exec rspec         # RSpec (requiere MySQL arrancado); incluye system specs
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
  No contienen reglas de negocio ni acceso directo a la base de datos: no usan
  `Model.find`, `Model.create`, `Model.where` ni `authenticate_by`. Toda
  interacción con ActiveRecord vive en services o en métodos del modelo.
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
  El trabajo se hace en ramas (`feat/<name>`, `fix/<name>`, `chore/<name>`,
  `docs/<name>`; minúsculas, guiones, **en inglés**) que se integran en
  `main` con `bin/ci` en verde. Una rama = una responsabilidad. Flujo
  completo: [`docs/git-workflow.md`](./docs/git-workflow.md).
- Los commits siguen Conventional Commits con `type` y `scope` en inglés
  (resumen en imperativo, en inglés): `feat:`, `fix:`, `docs:`, `test:`,
  `refactor:`, `chore:`.
- La versión vigente vive en el archivo [`VERSION`](./VERSION) (fuente única
  de verdad; la app la expone como `SilvaldeWebV2::APP_VERSION`) y su
  historial en [`CHANGELOG.md`](./CHANGELOG.md). SemVer: estamos en `0.x.y`
  hasta el lanzamiento público, que será `1.0.0`. No subas la versión dentro
  de una rama `feat/*`. Proceso de publicación:
  [`docs/versioning.md`](./docs/versioning.md).
- Las fases del proyecto y su estado están en
  [`docs/roadmap.md`](./docs/roadmap.md); actualízalo al completar una fase.
- Los agentes no hacen commits, push ni tags sin confirmación
  explícita del usuario. El push es una **acción aparte** que nunca se
  agrupa con un commit: aunque el usuario haya aprobado el commit, hay
  que esperar a su "sí, haz push" específico en el mismo turno. Los
  merges en `main` requieren una confirmación adicional y dedicada
  (ver "Reglas de merge"). **Las pull requests sí pueden ser abiertas
  por el agente** cuando el usuario lo pida explícitamente; el agente
  no debe abrirlas por su cuenta sin instrucción directa del usuario.
- **Confirma el nombre de la rama antes de crearla.** Al iniciar una
  tarea de código, además de comprobar la rama actual, el agente debe
  proponer un nombre de rama y esperar la confirmación explícita del
  usuario antes de ejecutar `git checkout -b`. Si el usuario no puede
  evaluar la propuesta, el agente explica primero las opciones y luego
  aplica la más sensata. Una vez creada, el agente avisa del nombre
  definitivo antes de seguir.
- **Una rama por feature o fix, no por slice.** Las ramas se crean
  únicamente para delimitar una feature (`feat/`) o un fix
  (`fix/`). Los slices son unidades de commit dentro de la misma rama,
  no ramas nuevas. Antes de empezar cada slice el agente confirma con
  el usuario si va a trabajar sobre la rama actual o si necesita abrir
  una rama nueva (en este último caso, aplica la regla anterior de
  confirmación del nombre).

## Documentación

La documentación extensa vive en [`AGENTS.full.md`](./AGENTS.full.md). Si ese
archivo crece demasiado, divide los temas en `docs/` y enlázalos desde ambos
archivos de directrices. Mantén siempre estas reglas críticas en este archivo
para que sean visibles en la primera carga del agente.

`AGENTS.md`, `AGENTS.full.md`, `README.md`, `CHANGELOG.md` y `docs/` están
versionados en git junto al código: la documentación es parte del producto y
debe actualizarse en la misma rama que el cambio que la motiva.

## Ritmo de trabajo y modelo mental

El usuario es junior y está aprendiendo. Las siguientes reglas evitan que
el agente implemente demasiada superficie en una sola sesión y deje al
usuario sin contexto.

- **Vertical slices, no capas horizontales.** Una sesión de trabajo es
  una unidad pequeña y verificable a mano (por ejemplo: "modelo User con
  validaciones" o "signup end-to-end"). No se implementa modelo +
  controller + vista + mailer + jobs + tests de todo en la misma sesión.
  Antes de empezar cada slice el agente debe: (a) explicar en una frase
  qué entra y qué queda fuera, (b) decir cómo se prueba a mano, (c)
  esperar a que el usuario lo valide antes de continuar.
- **Sub-slices dentro del slice.** Un slice puede contener varias
  features internas (por ejemplo: en `feat/user-model`, primero
  migración, luego modelo, luego validaciones, luego fixture/factory,
  luego test). Los sub-slices son unidades conceptuales para mantener
  el orden y el foco del trabajo; por defecto, todos los sub-slices
  de un mismo slice se commitean juntos en un único commit al cerrar
  el slice. Si el usuario lo pide, se pueden separar en commits
  individuales por sub-slice. El agente propone el mensaje de commit
  al final y espera la confirmación explícita antes de ejecutar
  `git commit`.
- **Mapa mental al inicio de cada sesión.** Al abrir una sesión de
  trabajo, el agente muestra un mapa breve del estado actual: tablas,
  controllers, URLs, tests, rama y commits sin pushear. Eso le da al
  usuario el contexto para decidir. Si la sesión anterior terminó con
  cambios sin comitear o sin pushear, se avisa al principio.
- **Explicar conceptos antes de preguntar opciones.** Si el usuario no
  puede evaluar una opción porque no conoce el concepto, el agente
  explica primero y pregunta después. Si el usuario dice "no sé", el
  agente propone la opción más sensata con su razonamiento y la aplica,
  sin esperar confirmación sobre algo que el usuario no puede juzgar.

## Skills locales

El proyecto puede definir skills propias en `.agents/skills/` (gestionado por
`skills-lock.json`). Antes de empezar una tarea, los agentes deben **revisar
las skills disponibles** y cargar las que apliquen al trabajo (frontend,
accesibilidad, SEO, etc.). Las skills globales del agente siguen disponibles;
esta regla añade una capa local al proyecto.

**Skills de superpowers (globales, obligatorias según el caso).** El agente
usa el plugin `superpowers`, que aporta skills de proceso. Debe cargarlas
antes de actuar siempre que apliquen, en orden proceso → implementación:

- `brainstorming` antes de cualquier trabajo creativo (feature nueva, cambio de comportamiento).
- `systematic-debugging` ante cualquier bug, test en rojo o comportamiento inesperado (antes de proponer fixes).
- `test-driven-development` al implementar feature o fix, antes de escribir código.
- `writing-plans` y `executing-plans` cuando hay una tarea multi-paso con spec.
- `verification-before-completion` antes de afirmar que algo está terminado o en verde.
- `requesting-code-review` / `receiving-code-review` al cerrar una tarea o recibir feedback.

La lista completa se consulta con el tool nativo `skill`.
