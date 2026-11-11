# CLAUDE.md

Las directrices del proyecto viven en `AGENTS.md` (las comparten Claude Code,
opencode y cualquier otro agente). Esta línea las carga en cada sesión:

@AGENTS.md

## Específico de Claude Code

- Permisos del proyecto en `.claude/settings.json`: los comandos de
  validación (`bin/ci`, `bundle exec rspec`, `bin/rubocop`…) se ejecutan sin
  preguntar y `git commit`, `git push`, `git merge`, `git tag` y similares
  **siempre** piden confirmación.
- Skill del proyecto: `/commit` (`.claude/skills/commit/`).
- Code review: `/project-review [slice|rama|version]`, solo cuando la pide el
  usuario. Corre en el agente global `project-reviewer` (ver
  `docs/agent-tooling.md`).
