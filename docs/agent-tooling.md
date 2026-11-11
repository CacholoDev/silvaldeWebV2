# Herramientas de agentes y del repositorio

Qué hay montado alrededor del código para que los agentes (Claude Code,
opencode) trabajen igual en cualquier PC, y qué reglas se comprueban solas
en lugar de depender de que alguien se acuerde.

## Dónde vive cada cosa

| Pieza | Dónde | Quién la usa |
| --- | --- | --- |
| Directrices del proyecto | `AGENTS.md` (+ `AGENTS.full.md`) | opencode y Codex lo leen directamente; Claude Code vía `CLAUDE.md` (`@AGENTS.md`). |
| Específico de Claude Code | `CLAUDE.md` | Claude Code |
| Permisos del proyecto | `.claude/settings.json` (Claude Code) y `opencode.json` (opencode) | Ver «Reglas configuradas» |
| Skills propias del proyecto | `.claude/skills/<nombre>/SKILL.md` (`commit`, `silweb-review`) | Claude Code y opencode (los dos leen `.claude/skills/`) |
| Skills de terceros (frontend-design, accessibility, seo-audit, tailwind-animations…) | Globales: `~/.agents/skills/` + `~/.claude/skills/`, instaladas desde `agent-dotfiles` (`skill-lock.json` + `sync-skills.sh`) | Todos los proyectos y PCs; no van en este repo |
| Ajustes personales de Claude Code | `.claude/settings.local.json` | Solo tu PC (ignorado por git) |
| Reviewer, reglas y skills globales | Repo privado `agent-dotfiles` (`~/Documentos/agent-dotfiles`) | Todos tus proyectos y PCs |

> Hasta noviembre de 2026, las skills de frontend, accesibilidad, SEO y
> animaciones de Tailwind se instalaban dentro del proyecto (`.agents/`), que
> estaba en `.gitignore`, así que al clonar en otro PC no venían. Ahora son
> globales y las instala `agent-dotfiles`. `.agents/` y `skills-lock.json`
> siguen ignorados para que no se dupliquen.

## Reglas configuradas (no solo escritas)

Una regla escrita en `AGENTS.md` depende de que el agente la lea y la
recuerde. Una regla **configurada** la aplica la herramienta siempre:

- **Permisos** (`.claude/settings.json` y `opencode.json`):
  - `git commit`, `git push`, `git merge`, `git rebase`, `git tag`,
    `git reset`, `gh pr create` y `gh pr merge` **siempre piden
    confirmación**, aunque el agente esté en modo automático.
  - `bin/ci`, `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit`,
    `bundle exec rspec` y los `git` de solo lectura se ejecutan sin preguntar.
  - `rails generate scaffold` está prohibido.
- **Cops de RuboCop propios** (`lib/rubocop/cop/silvalde/`, activados en
  `.rubocop.yml`, con specs en `spec/rubocop/`):
  - `Silvalde/NoActiveRecordInControllers`: en `app/controllers/`, prohíbe
    llamar a métodos de consulta o escritura de ActiveRecord sobre una
    constante (`Users::User.find_by`, `Catalog::Product.where`…). Se permiten
    los `*::Search` y `Model.new` para formularios.
  - `Silvalde/NoQueriesInModels`: en `app/models/`, prohíbe `scope`,
    `default_scope` y métodos de consulta sobre la propia clase.

  Como `bin/rubocop` corre en `bin/ci` y en GitHub Actions, una violación
  pone el CI en rojo. Límite conocido: no detecta consultas a través de
  asociaciones (`current_user.carts.where`); eso sigue siendo cosa de la
  review.
- **Dependabot agrupado** (`.github/dependabot.yml`): las subidas *minor* y
  *patch* de gemas llegan juntas en un único PR semanal, y las de GitHub
  Actions en otro. Las subidas *major* siguen llegando en PRs individuales
  porque pueden romper cosas. Antes llegaba un PR por gema y se acumulaban
  ramas `dependabot/*` sin revisar.

## Skill `commit`

`/commit` en Claude Code (o pidiéndolo en opencode) sigue la regla de
`AGENTS.md`:

1. Comprueba la rama y que lo verificado esté en verde.
2. Propone el mensaje (Conventional Commits en inglés) con la lista de
   archivos. No pega el diff, porque lo revisas en Source Control de VS Code.
3. Acepta cualquier OK natural («dale», «ok», «venga»…).
4. Nunca hace push sin un OK aparte.

## Code review: `/silweb-review`

**La lanzas tú**, cuando quieras (normalmente al cerrar un slice o antes del
PR de una versión). El agente nunca la lanza por su cuenta: la skill lleva
`disable-model-invocation: true`.

```text
/silweb-review slice      # lo que no has commiteado (o el último commit)
/silweb-review rama       # todo desde que la rama salió de main
/silweb-review version    # desde el último tag, con bin/ci completo
/silweb-review full       # auditoría de todo el código (deuda acumulada)
/silweb-review app/services/carts   # solo esas rutas
```

Está adaptada de la review de los proyectos Rails del trabajo (everest,
recyclia…: skill `rails-code-review`, agente `validator` y
`review-context.md`). Mantiene su estructura y cambia las reglas por las de
silWeb:

| Pieza | En el trabajo | En silWeb |
| --- | --- | --- |
| Barrido automático | `validate_rules.sh` (Discard, AASM, privados…) | `.claude/skills/silweb-review/scripts/validate_rules.sh`: AR en controllers, scopes, lecturas fuera de `Search`, rescue genérico, `permit!`, SQL interpolado, `html_safe`, ids a mano, texto sin `t()`, migraciones peligrosas, dinero en float, tests desactivados |
| i18n | Claves en `.yml` (a mano) | `check_i18n.rb`: claves usadas que faltan y paridad `es`/`en` |
| Checklist por tipo de archivo | Pundit, Draper, ViewComponent, BaseService | Controllers, services/`Search`, models, decorators, vistas/Turbo, jobs, migraciones, specs de silWeb |
| Entre capas | Campo de migración a vista, bang/no bang, i18n | Igual, con la estrategia de errores de silWeb (`errors` + `:unprocessable_content`) y Turbo (ids de `turbo_stream`) |
| Pasadas | Validator + Codex (lógica/seguridad) + pasada frontend/i18n | Las tres, hechas por el mismo subagente con foco separado |
| Ejemplos | `violation_examples.md` del template | `references/violation_examples.md` con casos reales de silWeb |

Se ejecuta en el subagente global **`project-reviewer`** (de solo lectura; vive
en tu repo `agent-dotfiles`), así que no llena tu conversación con lecturas de
archivos. Devuelve un veredicto, hallazgos verificados por severidad
(🔴/🟠/🟡/🟢), la tabla entre capas y qué comprobaciones ejecutó. Respeta los
«riesgos aceptados» de `AGENTS.full.md`.

En opencode no hay `/silweb-review`: pide «pasa la review con la skill
silweb-review» o usa `@project-reviewer`. El agente sigue la skill del
proyecto si existe.

El script también se puede lanzar a mano:
`.claude/skills/silweb-review/scripts/validate_rules.sh [archivos]`.

## Un PC nuevo, paso a paso

1. Clona el proyecto y sigue «Desarrollo local» del [README](../README.md).
2. Clona tus dotfiles y ejecuta `./install.sh` (ver el README de
   `agent-dotfiles`). Esto instala:
   - el reviewer, las reglas globales y las skills propias;
   - las skills de terceros;
   - los plugins de Claude Code (superpowers, engram, warp);
   - los MCP de engram y codegraph.
3. Opcional: trae las memorias de engram del otro PC con `engram export` en el
   PC de origen y `engram import` en el nuevo.
