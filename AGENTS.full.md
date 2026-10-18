# Directrices ampliadas para Silvalde Web

Este documento amplía [`AGENTS.md`](./AGENTS.md). No lo sustituye: las reglas
breves son el contrato mínimo que todo agente debe seguir.

## Idioma de código y documentación

- **En inglés**: nombres de ramas (`feat/`, `fix/`, `chore/`, `docs/`),
  identificadores de código (clases, módulos, métodos, variables, columnas),
  nombres de migraciones, mensajes de commit (type, scope y resumen),
  contenido de PRs, fixtures y seeds por convención.
- **En español**: documentación (`AGENTS.md`, `AGENTS.full.md`, `README.md`,
  `docs/`, `CHANGELOG.md` para el texto narrativo), comentarios extensos
  cuando aportan contexto al equipo, y las conversaciones con el usuario
  (sigue siendo junior y aprende mejor en su idioma).
- Esta regla es compatible con i18n de la UI: los textos visibles para la
  clienta (`es.yml`, etc.) se traducen aparte y no se ven afectados.

## Producto y límites funcionales

Silvalde Web es una tienda online de decoración. El producto debe priorizar
confianza, claridad y mantenimiento sencillo. El catálogo, el carrito, los
pedidos, el registro de clientes y el panel administrativo son dominios
relacionados, pero deben mantener límites claros.

La web es pública y el registro es opcional: la visitante ve primero el
catálogo/landing, no una pantalla de login. El login aparece solo cuando una
acción protegida lo requiere. Por tanto, la ruta raíz (`/`) apunta a la
landing (catálogo), nunca a `sessions#new`.

El registro de clientes existe para compras y para futuras ofertas o rebajas.
La comunicación comercial debe ser consentida, trazable y revocable. No
implementes campañas, pagos reales, facturación fiscal o integraciones externas
sin una especificación aprobada para esa tarea.

El panel administrativo debe aplicar autorización por rol y limitar el acceso a
usuarios, catálogo, pedidos, facturas y métricas según la necesidad operativa.
Nunca expongas datos administrativos en respuestas públicas ni confíes en
ocultar botones como mecanismo de autorización.

## Decisiones de stack (2026-10-11)

Decisiones tomadas con el usuario antes de la v0.2.0. No las cambies sin
consultar al usuario y actualizar esta sección y el changelog.

**Lo que usamos:**

- **Autenticación nativa de Rails 8** (`has_secure_password`/bcrypt y sesiones
  con cookie firmada). No Devise: la auth integrada es suficiente, la mantiene
  el core de Rails y reduce dependencias y «magia». Se implementa slice a
  slice a mano, no con el generador oficial de una vez.
- **Sesiones con cookie firmada** (tabla `sessions`). No JWT: JWT es para
  APIs stateless; en una web HTML las sesiones son más seguras y revocables.
- **Solid Queue y Solid Cache** sobre MySQL (ya configurados en el scaffold).
  No Redis ni Sidekiq: suficiente para la escala del proyecto y sin servicios
  extra que mantener. El código usa `Active Job`, así que migrar a Sidekiq en
  el futuro sería barato si hiciera falta.
- **RSpec + FactoryBot**: framework de tests del proyecto (los specs viven en
  `spec/` y las factories en `spec/factories/`). No Minitest.
- **Web HTML con Hotwire**: no hay API pública; por tanto nada de Grape,
  Swagger ni JWT. Si algún día se necesita una API, se especifica aparte
  (sección «Cambios y documentación»).
- **AASM para la máquina de estados de los pedidos** (`Order`): estados
  `pending → confirmed → shipped → delivered` (o `cancelled`), con transiciones
  definidas y documentadas (ver `docs/roadmap.md`, fase v0.5.0). La gema se
  añade a la `Gemfile` cuando lleguemos a esa fase; la decisión se registra
  ahora para no improvisar una máquina de estados a mano.

**Política de generadores:**

- Nunca `rails generate scaffold`: crea código que no encaja con la
  arquitectura de servicios y decorators.
- Generadores pequeños (`model`, `migration`) están permitidos como punto de
  partida; controllers, servicios, decorators y vistas se escriben a mano.
- La autenticación se escribe a mano, slice a slice (ver `AGENTS.md`, «Ritmo
  de trabajo y modelo mental»); no se usa el generador oficial para hacerlo
  todo de una vez.

**Candidatos futuros (decidir cuando toque, no instalar ahora):**

- **Pundit** (autorización por policies): candidato en v0.6.0 (panel admin) si
  los permisos crecen más allá del check de rol en `before_action`.
- **Grape/Swagger, Redis/Sidekiq**: solo si aparece una necesidad real
  documentada (API pública, volumen de jobs alto, etc.).

## Patrones de Rails

### Controllers

- Una acción debe recibir parámetros, autorizar, invocar un servicio y responder.
- Usa strong parameters y validaciones apropiadas para cada flujo.
- Un controller **no consulta ni escribe en la base de datos**: no usa
  `Model.find`, `Model.all`, `Model.where`, `Model.create`, `Model.update`,
  ni `authenticate_by` directamente. Esa interacción es responsabilidad de los
  services (o de un método del modelo). La única excepción es la infraestructura
  transversal (la concern `Authentication` para la sesión por cookie).
- No uses callbacks de controller para esconder reglas de negocio.
- Devuelve estados HTTP correctos y errores de validación comprensibles.

### Services

- Un servicio hace **una única cosa** (una sola responsabilidad, un caso de uso).
  Si un servicio empieza a hacer dos cosas distintas, se divide en dos servicios.
- Un servicio representa un caso de uso, no una colección arbitraria de helpers.
- Usa transacciones cuando una operación modifique varias tablas.
- Usa métodos bang para invariantes que no deberían fallar silenciosamente
  (`create!`, `update!`, `save!`), y métodos no bang únicamente cuando se esperan
  errores de validación que el usuario pueda corregir.
- No captures excepciones genéricas. Captura solo errores conocidos y decide de
  forma explícita cómo se comunican.
- Devuelve resultados consistentes y documenta cualquier resultado distinto de
  una entidad o colección esperada.

### Models

- Mantén en el modelo asociaciones, validaciones, constraints de dominio y
  comportamiento pequeño propio de la entidad.
- Añade índices y restricciones de base de datos para unicidad e integridad; una
  validación Ruby por sí sola no evita carreras.
- Evita `default_scope` y scopes personalizados salvo que una decisión de dominio
  documentada los haga imprescindibles.
- Para eliminaciones o archivado, decide explícitamente si se necesita borrado
  lógico; no lo añadas automáticamente a todos los modelos.

### Decorators y presentación

- Un decorator puede formatear nombres, precios, estados y etiquetas para la UI.
- No debe mutar persistencia ni hacer llamadas de red.
- No dupliques reglas de negocio en vistas o decorators: expón un resultado del
  servicio o del modelo.
- Centraliza formatos de moneda, fechas y estados para que storefront y admin
  sean coherentes.

## Frontend

- Usa Tailwind siguiendo los patrones existentes y evita estilos inline salvo una
  necesidad técnica justificada.
- Prefiere HTML semántico, navegación por teclado, labels asociados y mensajes
  de error accesibles.
- Usa Turbo Frames/Streams y Stimulus para interacciones incrementales.
- Evita añadir JavaScript global o una SPA si una interacción local resuelve el
  problema.
- Las imágenes de producto deben contemplar texto alternativo, dimensiones y
  tratamiento de errores.
- No uses colores, tamaños o componentes nuevos sin comprobar la coherencia con
  la interfaz existente.

## Datos, seguridad y privacidad

- Las credenciales locales viven en `.env`; usa `.env.example` como contrato de
  variables sin secretos.
- Usa consultas parametrizadas y las APIs de Active Record; nunca interpolar
  entrada del usuario en SQL.
- Autoriza cada operación administrativa en servidor.
- Protege sesiones, contraseñas, tokens y datos de pedidos. No registres
  contraseñas, tokens ni datos de pago.
- Minimiza los datos personales almacenados y ofrece una estrategia clara para
  consentimiento y baja de comunicaciones comerciales.
- Valida cargas de archivos, limita tipos/tamaños y utiliza Active Storage de
  forma segura.

## Base de datos y migraciones

- Una migración debe ser reversible cuando sea posible y segura para datos
  existentes.
- Añade índices para claves foráneas, búsquedas frecuentes y unicidad.
- No borres ni renombres columnas con datos sin un plan de migración en fases.
- Usa nombres de tablas y columnas consistentes con Rails.
- Los cambios de esquema deben incluir pruebas o una verificación reproducible.

## Pruebas y calidad

- Usa RSpec y FactoryBot: los specs viven en `spec/` y las factories en
  `spec/factories/`. Escribe primero el spec que fija el comportamiento y luego
  el código de producción (skill `test-driven-development`).
- Cubre casos de éxito, validación, autorización y límites relevantes.
- Para cambios de UI o flujos completos, considera system tests con Capybara.
- Ejecuta el conjunto mínimo relevante y después las comprobaciones de seguridad
  cuando el cambio afecte a autenticación, autorización, entradas o datos.
- No cambies un test existente solo porque contradice una implementación nueva;
  primero determina el contrato correcto y pide confirmación si el alcance no
  está claro.

## Cambios y documentación

Antes de implementar una funcionalidad transversal, describe en el cambio:

1. Qué usuario o proceso resuelve.
2. Qué modelos, permisos y datos afecta.
3. Qué sucede ante errores y entradas inválidas.
4. Cómo se prueba y cómo se revierte.

Mantén el README orientado a incorporación y operación local. Mantén este
documento orientado a decisiones que los agentes deben aplicar. Usa `docs/` para
especificaciones funcionales, decisiones arquitectónicas o procedimientos
largos, y enlázalos desde `AGENTS.md`.

## Flujo de ramas y releases

El flujo de trabajo con git (tipos de rama, ciclo de una feature, formato de
commits) está en [`docs/git-workflow.md`](./docs/git-workflow.md); el proceso
de publicación de versiones y dónde vive la versión, en
[`docs/versioning.md`](./docs/versioning.md); las fases del proyecto, en
[`docs/roadmap.md`](./docs/roadmap.md). Esos documentos son la referencia
operativa; respétalos y actualízalos cuando el flujo cambie.

Dos decisiones que los atraviesan:

- La seguridad es transversal (brakeman, bundler-audit e importmap audit en
  cada `bin/ci`), no una fase posterior. Las correcciones de seguridad usan
  rama `fix/` y sección `Seguridad` en el changelog.
- Los agentes nunca hacen commits, merges, push ni tags sin confirmación
  explícita del usuario.

## Definición de terminado

Una tarea está terminada cuando:

- se ha verificado ejecutando (tests, linters, arranque) y se muestra la
  evidencia, no solo la afirmación (skill `verification-before-completion`);
- el comportamiento solicitado funciona en los flujos afectados;
- la autorización y la validación están cubiertas;
- no se han introducido secretos ni regresiones conocidas;
- los tests y linters relevantes pasan, o se informa claramente de la limitación;
- el README, `CHANGELOG.md` o la documentación relacionada refleja cualquier
  cambio operativo o visible.

