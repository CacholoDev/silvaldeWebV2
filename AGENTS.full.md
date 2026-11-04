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
landing (catálogo), nunca a `sessions#new`. La landing es la presentación
completa de la tienda: productos destacados, ofertas y rebajas, galería de
fotos y acceso al catálogo por categorías; el login es siempre opcional y
nunca es la portada.

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

**Decisiones de datos del catálogo (2026-10-24):**

- **Namespace `Catalog::`** para models, services y controllers del catálogo
  (tablas sin prefijo: `categories`, `products`, `variants`), coherente con
  `Auth::` y `Users::`.
- **Precios en céntimos** (`price_cents`, entero; euros fijos, sin columna de
  moneda): evita errores de redondeo de los decimales; el formato «45,00 €»
  lo prepara un decorator.
- **Variante obligatoria para la venta**: todo producto necesita al menos una
  variante para estar a la venta; los artículos únicos llevan una sola
  variante («Única»). Un producto sin variantes puede guardarse como
  borrador, pero no está disponible. El stock vive solo en la variante; no
  hay stock a nivel de producto.
- **Disponibilidad = stock de la variante** (`stock > 0`). El producto está
  disponible si alguna de sus variantes lo está.
- **Slug automático** desde el nombre con `parameterize` (URL-safe: minúsculas
  y sin acentos), usado en las URLs públicas. Se genera al crear y no cambia
  al renombrar, para no romper enlaces existentes.
- **Unicidad de nombres insensible a acentos y mayúsculas**: la validación es
  `case_sensitive: false` y el collation por defecto de MySQL
  (`utf8mb4_0900_ai_ci`) hace que «Jarrón» y «Jarron» cuenten como el mismo
  nombre tanto en la validación como en el índice único.

**Decisiones del carrito (2026-11-01):**

- **Namespace `Carts::`** para models y services del carrito (tablas `carts`
  y `cart_items`), coherente con `Users::` y `Catalog::`. Zeitwerk no admite
  la clase `Cart` junto al directorio `app/services/cart/`.
- **Precio congelado al añadir** (`unit_price_cents` en `CartItem`, snapshot):
  un cambio de precio posterior en el catálogo no reescribe los carritos
  existentes.
- **El stock no se toca en el carrito**: el carrito es intención de compra; el
  stock se valida y descuenta en el checkout (v0.5.0), con transacción y
  bloqueo de fila.
- **Una línea por variante** (índice único `cart_id, variant_id`); repetir la
  variante suma cantidades, no duplica líneas.
- **Fusión al login**: el carrito de invitada se fusiona con el de la cuenta
  sumando cantidades de las variantes comunes; nunca sobreescribiendo.
- **Caducidad a los 6 meses de inactividad** (tope de retención por
  seguridad): `Carts::Cart::MAX_INACTIVITY`. Las consultas viven en
  `Carts::Search` y el purge será un job recurrente silencioso (sin avisos a
  la clienta). El carrito de invitada vive en la sesión (cookie) y no necesita
  tope.
- **La pertenencia se decide al resolver el carrito** (review de v0.4.0): el
  carrito de la sesión solo se muestra y se escribe si es de invitada o de la
  cuenta activa; un carrito de otra cuenta se olvida, no se toca.
  `terminate_session` borra el `cart_id` de la sesión y signup y login
  reclaman/fusionan el carrito de invitada igual (`merge_current_cart_into`).
- **Riesgos aceptados (review de v0.4.0)**: la validación de unicidad
  `cart_id + variant_id` no es segura ante carreras (dos pestañas añadiendo la
  misma variante pueden disparar `RecordNotUnique` → error 500; sin corrupción
  gracias a la transacción); el purge no usa batching (volumen diario bajo);
  y el contador del header suma cantidades en cada petición (una consulta
  indexada por página).

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

El código se organiza por **dominio** en namespaces (`Auth`, `Users`, …): cada
dominio agrupa sus controllers, models y services en
`app/controllers/<dominio>/`, `app/models/<dominio>/` y
`app/services/<dominio>/`. La infraestructura transversal (concerns, `Current`,
`ApplicationRecord`, páginas como `Home`) puede quedarse en la raíz.

### Controllers

- Una acción debe recibir parámetros, autorizar, invocar un servicio y responder.
- Usa strong parameters y validaciones apropiadas para cada flujo.
- Un controller **no consulta ni escribe en la base de datos**: no usa
  `Model.find`, `Model.all`, `Model.where`, `Model.create`, `Model.update`,
  ni `authenticate_by` directamente. Las consultas se delegan en services de
  búsqueda (`search.rb`). La única excepción es la infraestructura transversal
  (la concern `Authentication` para la sesión por cookie).
- No uses callbacks de controller para esconder reglas de negocio.
- Devuelve estados HTTP correctos y errores de validación comprensibles.

### Services

- Un servicio hace **una única cosa** (una sola responsabilidad, un caso de uso).
  Si un servicio empieza a hacer dos cosas distintas, se divide en dos servicios.
- Las **consultas de lectura** se agrupan en un service `search.rb` por dominio
  (`app/services/<contexto>/search.rb`, p. ej. `Auth::Search`). Los services de
  caso de uso y los controllers delegan ahí sus búsquedas.
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
  comportamiento pequeño propio de la entidad: **métodos sin parámetros** que
  operan sobre su propio estado (`available?`, `expired?`, …).
- **Nada de consultas en el modelo**: ni `where`, ni `find_by`, ni `lookup`, ni
  scopes (`scope :x`, `default_scope`), ni métodos `find_by_xxx`. Las consultas
  de lectura viven en el service `search.rb` del dominio
  (`app/services/<contexto>/search.rb`, p. ej. `Carts::Search`); las escrituras
  en services de caso de uso. Ejemplo real: los scopes `active`/`expired` que
  nacieron en `Carts::Cart` se movieron a `Carts::Search`.
- El nombre corto del modelo para i18n y formularios (`product`, no
  `catalog_product`) lo define `ApplicationRecord.model_name` (demoduliza el
  nombre). Es infraestructura de nombres: los modelos individuales **no**
  declaran `ActiveModel::Name` ni sobreescriben `model_name`.
- Añade índices y restricciones de base de datos para unicidad e integridad; una
  validación Ruby por sí sola no evita carreras.
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
- El stock solo se modifica dentro de una transacción con bloqueo de fila
  (`with_lock` / `SELECT ... FOR UPDATE`) y validando stock suficiente, con
  rollback completo si algo falla: dos pedidos simultáneos no pueden vender
  la misma unidad (se implementa en el checkout de v0.5.0).
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
  cambio operativo o visible;
- una versión que se cierra (p. ej. `0.3.0`) ha pasado el code review de
  superpowers (`requesting-code-review` / `receiving-code-review`) antes de
  abrir su PR. No se revisa cada slice: solo la versión completa, al final.

