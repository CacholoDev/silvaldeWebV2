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
| Skills propias del proyecto | `.claude/skills/<nombre>/SKILL.md` (p. ej. `commit`) | Claude Code y opencode (los dos leen `.claude/skills/`) |
| Skills de terceros del proyecto | `.agents/skills/` + `skills-lock.json` (instaladas con `npx skills`) | opencode y Codex; versionadas en git |
| Ajustes personales de Claude Code | `.claude/settings.local.json` | Solo tu PC (ignorado por git) |
| Reviewer, reglas y skills globales | Repo privado `agent-dotfiles` (`~/Documentos/agent-dotfiles`) | Todos tus proyectos y PCs |

> Hasta noviembre de 2026, `.agents/` y `skills-lock.json` estaban en
> `.gitignore`. Por eso, al clonar en un PC nuevo, las skills de frontend,
> accesibilidad, SEO y animaciones de Tailwind no venían. Ya no se ignoran:
> en el PC donde estén instaladas, súbelas con un commit
> `chore: version project agent skills`.

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

## Review de fin de versión: `project-reviewer`

Es un agente **global**: vive en `agent-dotfiles/agents/project-reviewer.md`
y sirve para todos tus proyectos. Lee las reglas del proyecto en el que está
(`CLAUDE.md`, `AGENTS.md`, `AGENTS.full.md` y `docs/`), revisa el rango de la
versión (desde el último tag hasta `HEAD`), ejecuta las validaciones y
devuelve un veredicto con hallazgos verificados por severidad. Respeta los
«riesgos aceptados» documentados. Es de solo lectura: no edita ni commitea.

Uso: «pasa el project-reviewer a la versión 0.4.0» (Claude Code lo lanza como
subagente; en opencode, `@project-reviewer`).

## Un PC nuevo, paso a paso

1. Clona el proyecto y sigue «Desarrollo local» del [README](../README.md).
2. Clona tus dotfiles y ejecuta `./install.sh` (ver el README de
   `agent-dotfiles`). Esto instala el reviewer, las reglas globales y las
   skills propias.
3. Instala los plugins de Claude Code (`/plugin` → `superpowers`, `engram`).
4. Si el proyecto tiene `skills-lock.json` pero no `.agents/skills/`,
   restaura las skills con `npx skills` usando las fuentes del lock.
5. Opcional: trae las memorias de engram del otro PC con `engram export` en el
   PC de origen y `engram import` en el nuevo.
