---
name: silweb-review
description: Code review de silWeb (Silvalde Web) contra sus propias reglas, adaptada de la review rails-code-review / validator de los proyectos Rails del trabajo. Solo se lanza a mano con /silweb-review [slice|rama|version|ruta…|full]; nunca por iniciativa del agente.
disable-model-invocation: true
context: fork
agent: project-reviewer
argument-hint: "[slice|rama|version|full|ruta…]"
---

# silWeb review

Review de código de silWeb con sus reglas. Está adaptada de la review de los
proyectos Rails del trabajo (skill `rails-code-review` + agente `validator` +
`review-context.md`), que lleva meses afinándose. De allí vienen las **tres
pasadas** con foco separado, la **comprobación entre capas** y el **barrido
automático con script**. Aquí cada regla es la de silWeb: no hay Discard, AASM,
Pundit, Draper ni ViewComponent.

Eres de **solo lectura**: no editas, no commiteas, no haces push. Lees,
ejecutas comprobaciones y reportas en **español**. El usuario es junior y está
aprendiendo, así que cada hallazgo explica brevemente el *porqué*.

Argumentos recibidos: `$ARGUMENTS`

## Paso 0. Alcance

| Argumento | Qué entra | Validación |
| --- | --- | --- |
| `slice` (o vacío con cambios sin commitear) | `git diff HEAD` + archivos nuevos (`git status --porcelain`, líneas `??`). Sin cambios: el último commit. | Script + `bin/rubocop` + specs de lo tocado |
| `rama` (o vacío sin cambios) | `git merge-base HEAD main`..`HEAD` + lo sin commitear | Script + `bin/rubocop` + specs afectados |
| `version` | Último tag (`git describe --tags --abbrev=0`)..`HEAD` | `bin/ci` completo |
| `full` | Todo `app/`, `spec/`, `db/migrate` (auditoría de deuda acumulada) | Script + `bin/rubocop` + `bundle exec rspec` |
| rutas | Solo esos archivos o directorios | Script sobre ellos + sus specs |

Muestra lo que entra (`git status --short`, `git log --oneline <rango>`,
`git diff --stat <rango>`). Los commits previos de la rama solo son contexto.

## Paso 1. Carga las reglas

Lee `AGENTS.md` y `AGENTS.full.md` (sobre todo «Patrones de Rails»,
«Frontend», «Datos, seguridad y privacidad» y las **decisiones y riesgos
aceptados**). Un riesgo aceptado documentado **no** es un hallazgo, salvo que
el código ya no cumpla lo que dice la decisión. Si una regla de esta skill
contradice `AGENTS.md`, manda `AGENTS.md`.

Para ejemplos de código correcto e incorrecto de silWeb, consulta
`references/violation_examples.md` (está junto a este archivo, en
`.claude/skills/silweb-review/`).

## Paso 2. Barrido automático (obligatorio)

```bash
.claude/skills/silweb-review/scripts/validate_rules.sh [archivos del alcance]
bin/rubocop [archivos .rb del alcance]
```

- `validate_rules.sh` sin argumentos barre todo; con archivos, solo esos.
  Incluye `check_i18n.rb`, que comprueba que las claves `t("…")` usadas
  existen en `es` y `en` y que ambos locales tienen las mismas claves.
- **VIOLATION** = regla rota, entra en el informe salvo falso positivo
  justificado. **AVISO** = míralo y decide; reporta solo si de verdad es un
  problema.
- Después, los specs del alcance (o `bin/ci` en modo `version`). Si algo no se
  puede ejecutar (p. ej. falta la BD), dilo y sigue. **No inventes
  resultados.**

## Paso 3. Lee de verdad

Lee los archivos del alcance **enteros**, no solo los hunks, más sus specs y
lo que los llama o lo que llaman. Antes de afirmar que algo «no existe» o
«no se usa», búscalo.

## Paso 4. Pasada 1: reglas de silWeb (checklist por tipo de archivo)

### Controllers (`app/controllers/**`)
- [ ] Solo orquestan: params → servicio o `Search` → responder. Sin reglas de
      negocio y sin ActiveRecord directo (`Model.find/where/create…`,
      `authenticate_by`). Excepción: concern `Authentication`.
- [ ] Lecturas con `<Dominio>::Search`; con `find_*!` cuando el recurso debe
      existir (404). Construir `Model.new` para un formulario está permitido.
- [ ] **Propiedad**: todo lo que pertenece a alguien se busca **a través de su
      dueño** (`Carts::Search.find_item_by_id!(current_cart, params[:id])`,
      `current_user`), nunca solo por id (IDOR).
- [ ] Strong params con `permit` explícito. Sin `permit!` y sin pasar `params`
      entero a un service.
- [ ] Parámetros numéricos normalizados en el borde (`params[:quantity].to_s.to_i`):
      un array o un hash no puede provocar un 500.
- [ ] Estrategia de errores: el service devuelve el objeto con `errors` → el
      controller decide con `errors.any?`/`errors.empty?`, y en el fallo responde
      `:unprocessable_content` (HTML `render`, o `turbo_stream` con status).
- [ ] Respuestas `turbo_stream` **y** fallback HTML (`format.html`) cuando la
      acción se usa desde un formulario.
- [ ] Mensajes con `t(...)`; nada de texto literal en `notice:`/`alert:`.
- [ ] `private` está permitido aquí (strong params y helpers de render).

### Services (`app/services/<dominio>/**`)
- [ ] Un caso de uso por service (`self.call(...)` con keywords), una sola
      responsabilidad. Si hace dos cosas, son dos services.
- [ ] **Lecturas por el `Search` del dominio**, también desde un service. Un
      service de caso de uso no hace `Model.where/find_by` (escrituras
      masivas acotadas como `Session.where(user:).destroy_all` se toleran;
      márcalas si crecen).
- [ ] `search.rb`: métodos de clase, `includes` donde se itera (N+1), `nil`
      seguro (`return nil if id.blank?` sin consulta inútil), y documentación
      breve de qué devuelve.
- [ ] Transacción cuando escribe en varias tablas. Bang (`save!`, `update!`)
      para invariantes; sin bang solo cuando el usuario puede corregir el
      error, y entonces devuelve el objeto con `errors`.
- [ ] Sin `rescue` genérico. Solo errores conocidos (p. ej.
      `ActiveRecord::RecordNotUnique` con un reintento acotado).
- [ ] Concurrencia: lo que dependa de unicidad tiene índice único en BD (no
      basta la validación); stock y dinero con `with_lock` dentro de la
      transacción.
- [ ] Rechaza en el borde los valores imposibles (cantidades ≤ 0, ids en
      blanco) añadiendo un error, no fallando más adentro.

### Models (`app/models/<dominio>/**`)
- [ ] Solo asociaciones, validaciones, constantes de dominio y métodos **sin
      parámetros** sobre su estado (`available?`, `expired?`).
- [ ] **Ninguna consulta**: ni `where`, ni `find_by`, ni `scope`, ni
      `default_scope`. Las vigila el cop `Silvalde/NoQueriesInModels`.
- [ ] No declaran `model_name` ni `ActiveModel::Name`: eso lo resuelve
      `ApplicationRecord`.
- [ ] Toda validación de unicidad o integridad tiene su índice o constraint en
      la migración.

### Decorators (`app/decorators/**`)
- [ ] Heredan de `ApplicationDecorator` (`SimpleDelegator`). Solo formato
      (precios con `euros`, etiquetas con `I18n.t`). Sin consultas, sin
      escribir y sin reglas de negocio duplicadas.
- [ ] Dinero siempre en céntimos (`*_cents` integer); se formatea solo aquí o
      con `format_cents`.

### Vistas y partials (`app/views/**`)
- [ ] Sin consultas ni llamadas a `Search`: los datos llegan del controller
      (variables o `locals`).
- [ ] Todo texto visible con `t(...)`. Formularios con `label` asociado
      (`sr-only` si no se ve), `dom_id` para los ids, `alt` en imágenes.
- [ ] Los ids que actualiza `turbo_stream.update("x")` existen en la vista
      (`id="x"` o `turbo_frame_tag "x"`).
- [ ] Enlaces que salen de un `turbo_frame` llevan `data: { turbo_frame: "_top" }`.
- [ ] Tailwind con los tokens existentes (`text-muted`, `border-line`,
      `bg-paper`…). Sin estilos inline ni colores nuevos sin justificar.

### Jobs (`app/jobs/**`)
- [ ] Delegan en un service (el job solo programa y llama). Idempotentes y
      seguros si se ejecutan dos veces.

### Migraciones (`db/migrate/**`)
- [ ] Reversibles. Índices en claves foráneas y búsquedas. Si una referencia
      lleva `index: false`, debe haber un índice compuesto que empiece por esa
      columna.
- [ ] Sin borrar ni renombrar columnas con datos sin un plan en fases. Dinero
      en integer (céntimos), nunca float.

### Specs (`spec/**`)
- [ ] Hay spec para cada comportamiento nuevo (TDD), incluidos los bordes:
      nil o en blanco, negativos, duplicados, params con forma inesperada
      (array), recurso ajeno (404), carrera si aplica.
- [ ] **Tests existentes modificados**: márcalo siempre y comprueba que fue por
      un cambio real de contrato (p. ej. una consulta que se mueve a un
      `Search`), sin perder cobertura.
- [ ] Flujos de UI con Turbo cubiertos con un system spec (`spec/system/`).
- [ ] Sin `xit`, `fit`, `focus` ni `skip`.

## Paso 5. Comprobación entre capas

El error más común cuando se trabaja por capas o con varios agentes.

**5.1 Campo de punta a punta.** Para cada atributo nuevo o renombrado, rellena:

| Campo | Migración | Modelo (validación) | Service | Strong params | Form | Vista detalle | Locales es/en | Factory/spec |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

Si un campo editable falta en alguna capa → hallazgo **ALTO** (o CRÍTICO si se
pierde el dato). Marca «n/a» cuando la capa no aplica de verdad.

**5.2 Estrategia de errores coherente.**

- Si el service devuelve el objeto con `errors` (sin bang), el controller mira
  `errors` y el spec del service comprueba `result.errors[...]`.
- Si el service usa bang, el error es inesperado, se propaga y el spec usa
  `raise_error`.

Si los dos patrones se mezclan, es un hallazgo.

**5.3 i18n.** Toda clave nueva existe en `es` y `en`, que comprueba el script.
Además, revisa que en español el género sea correcto («carrito actualizado»,
«cantidad actualizada»), que no haya claves huérfanas que el cambio dejó sin usar, y
las claves dinámicas (`t("x.#{y}")`) que el script lista para revisar a mano.

**5.4 Rutas y Turbo.** Cada path usado en vistas y controllers existe en
`config/routes.rb`, y los ids de `turbo_stream` coinciden con los de la vista.

## Paso 6. Pasada 2: lógica y seguridad

Busca lo que el script y la pasada 1 no detectan:

1. **Bugs lógicos**: casos límite (nil, vacío, cero, negativos, duplicados,
   límites), orden de operaciones, resultados que se pierden, errores que se
   tragan.
2. **Concurrencia**: doble clic o dos pestañas (unicidad + reintento),
   carritos o sesiones que cambian a mitad de petición, stock.
3. **Seguridad**:
   - **IDOR**: ¿se puede tocar el carrito, la línea o el perfil de otra
     persona cambiando un id?
   - **Mass assignment**, **SQL** con interpolación, **XSS** (`html_safe`,
     `raw`).
   - **Open redirect** (`redirect_to params[...]`; `redirect_back` necesita
     `fallback_location`).
   - **Sesión**: `reset_session` y la rotación al iniciar sesión; tokens con
     caducidad y de un solo uso; nada de contraseñas ni tokens en logs.
   - Mensajes de error que revelan datos, como si un email existe.
4. **Integridad de datos**: el dinero en céntimos, las transacciones
   completas, y las FKs con `dependent` coherente.
5. **Rendimiento**: N+1 en listados, consultas repetidas en cada petición
   (memoización como `current_cart`) y listados sin paginar.

## Paso 7. Pasada 3: frontend, i18n, UX y accesibilidad

1. **i18n**: lo del 5.3, y el selector de idioma conserva la página.
2. **UX**:
   - Los formularios muestran los errores de validación junto al campo.
   - Las acciones destructivas tienen confirmación cuando borran algo
     valioso.
   - Turbo actualiza todo lo que cambia: el contador del carrito, el total y
     el mensaje.
   - Sin JavaScript, el flujo sigue funcionando (fallback HTML).
3. **Accesibilidad**:
   - Un `label` en cada input, y `alt` en las imágenes.
   - Foco visible, y orden de tabulación lógico.
   - `caption`/`scope` en las tablas, y `role="status"` en los mensajes que
     cambian (como `cart_feedback`).
4. **Coherencia visual**: los mismos componentes, tokens y espaciados que las
   pantallas vecinas.

## Paso 8. Verifica cada hallazgo

Para cada posible hallazgo, construye el **escenario concreto** que falla
(entrada → resultado incorrecto) y compruébalo contra el código. Si puedes,
demuéstralo con un comando de solo lectura, por ejemplo ejecutando un spec que
ya existe. Si no puedes construir el escenario, descártalo o márcalo «a
confirmar». Pocos hallazgos ciertos valen más que muchos dudosos. No reportes
estilo que ya cubre RuboCop ni gustos personales.

## Paso 9. Informe

```markdown
## Veredicto
✅ Listo | ⚠️ Listo con cambios menores | ❌ No listo — una frase de por qué.
Alcance: <modo> · <n> archivos · <rango>

## Hallazgos
### 🔴 Críticos (bloquean: bug en producción, dato perdido, vulnerabilidad)
- `ruta/archivo.rb:42` — Qué pasa. **Escenario:** … **Regla:** AGENTS.md › … **Arreglo:** …
### 🟠 Altos (corregir antes del commit/PR: regla rota, capa sin campo, i18n que falta)
### 🟡 Medios (recomendación fuerte)
### 🟢 Bajos (sugerencia, no bloquea)

## Entre capas
(tabla del 5.1 si hubo campos nuevos; estrategia de errores e i18n en una línea cada una)

## Por pasada
| Pasada | Resultado |
| --- | --- |
| 1. Reglas de silWeb | ✅ / n hallazgos |
| 2. Lógica y seguridad | … |
| 3. Frontend, i18n, UX | … |

## Lo que está bien
2-4 puntos concretos, para reforzar lo que conviene repetir.

## Comprobaciones ejecutadas
- `validate_rules.sh …` → 0 violaciones, 2 avisos (revisados: …)
- `bin/rubocop …` → sin ofensas
- `bundle exec rspec …` → N ejemplos, 0 fallos

## Riesgos aceptados que siguen vigentes
- … (de AGENTS.full.md), y si alguno ha dejado de ser cierto.
```

Omite las secciones vacías. Si no hay hallazgos, dilo claramente.

**Protocolo de corrección** (lo aplica el agente principal, no tú):

| Severidad | Qué se hace |
| --- | --- |
| 🔴 | Se corrige con un spec que lo reproduzca y se vuelve a pasar la review (máximo 2 veces). |
| 🟠 | Se corrige antes del commit o del PR, o se documenta como riesgo aceptado. |
| 🟡 y 🟢 | El usuario decide. |
