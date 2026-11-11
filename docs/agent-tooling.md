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
| Skills propias del proyecto | `.claude/skills/<nombre>/SKILL.md` (`commit`); perfil de review en `.claude/review/` | Claude Code y opencode (los dos leen `.claude/skills/`) |
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

## Code review: `/project-review`

**La lanzas tú**, cuando quieras (normalmente al cerrar un slice o antes del
PR de una versión). El agente nunca la lanza por su cuenta: la skill lleva
`disable-model-invocation: true`.

```text
/project-review slice      # lo que no has commiteado (o el último commit)
/project-review rama       # todo desde que la rama salió de main
/project-review version    # desde el último tag, con bin/ci completo
/project-review full       # auditoría de todo el código (deuda acumulada)
/project-review app/services/carts   # solo esas rutas
```

Tiene dos piezas:

| Pieza | Dónde | Qué aporta |
| --- | --- | --- |
| Skill global `/project-review` | Repo `agent-dotfiles` (`skills/project-review/`) | El método, igual en todos tus proyectos: tres pasadas (reglas; lógica y seguridad; frontend, i18n y accesibilidad), comprobación entre capas, hallazgos verificados con escenario e informe por severidad. Barrido automático con `rails_checks.sh` (rescue genérico, `permit!`, SQL interpolado, `html_safe`, *open redirect*, ids a mano, texto sin `t()`, migraciones peligrosas, tests desactivados) y `check_i18n.rb` (claves que faltan y paridad `es`/`en`). |
| Perfil de silWeb | `.claude/review/` (este repo) | `rules.md`: checklist de silWeb por tipo de archivo (`Search`, propiedad por `current_cart`, Turbo, céntimos…), que manda sobre el genérico. `examples.md`: violaciones reales, varias de la review de la 0.4.0. `checks.tsv`: comprobaciones automáticas propias (consultas en controllers, scopes, lecturas fuera de `Search`…). |

El método viene de la review de los proyectos Rails del trabajo (skill de
code review, agente validator y contexto de review), reescrito en genérico y
sin nada específico de la empresa.

Se ejecuta en el subagente global **`project-reviewer`** (de solo lectura),
así que no llena tu conversación con lecturas de archivos. Respeta los
«riesgos aceptados» de `AGENTS.full.md`.

En opencode no hay `/project-review`: pide «pasa la review» o usa
`@project-reviewer`; el agente lee y sigue la misma skill.

El barrido también se puede lanzar a mano desde la raíz del proyecto:
`~/.claude/skills/project-review/scripts/rails_checks.sh [archivos]`.

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
