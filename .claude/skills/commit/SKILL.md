---
name: commit
description: Use when a slice of Silvalde Web is finished and verified and it is time to commit it, or when the user says "commit", "haz commit", "commitea" or similar. Proposes a Conventional Commit message in English and commits only after the user agrees.
---

# Commit de un slice

Reglas de origen: `AGENTS.md`, sección «Git, ramas, commits y versiones».

## Pasos

1. **Comprueba la rama** (`git branch --show-current`). Si es `main`, para:
   propón una rama (`feat/…`, `fix/…`, `chore/…`, `docs/…`) y espera el OK
   antes de seguir.
2. **Mira qué entra**: `git status --short` y `git diff --stat` (más
   `git diff --cached --stat` si ya hay algo en el stage). Si hay archivos que
   no son del slice (otra tarea, `.env`, logs, `tmp/`), sepáralos o pregunta.
3. **Verifica antes de proponer**: los specs del slice y `bin/rubocop` en
   verde (o `bin/ci` si el slice es grande). Si algo falla, no propongas el
   commit: arréglalo o explica por qué.
4. **Propón el mensaje**, en inglés, Conventional Commits:
   - `type(scope): resumen en imperativo` (≤ 72 caracteres), con tipos
     `feat`, `fix`, `docs`, `test`, `refactor` o `chore`.
   - Cuerpo opcional (en inglés) con el *porqué* cuando no sea obvio.
   - Tests en el mismo commit que el código que prueban.
5. **Enséñalo así**, sin pegar el diff (el usuario lo revisa en el panel
   Source Control de VS Code):

   ```
   Rama: feat/xxx
   Entran: app/services/carts/add_item.rb, spec/services/carts/add_item_spec.rb (+2)
   Verificado: bundle exec rspec spec/services/carts → 24 ejemplos, 0 fallos

   feat(cart): retry add-to-cart once on duplicate line
   ```

   Y pregunta algo corto: «¿Lo commiteo?».
6. **Interpreta la respuesta por la intención.** Cualquier afirmativa vale
   («dale», «ok», «venga», «vamos», «sí», «perfecto», «adelante», 👍…). Si
   pide otro mensaje, partir en dos commits o quitar un archivo, hazlo y
   vuelve a proponer. Si es ambigua, pregunta.
7. **Commitea** (`git add <archivos>` + `git commit`) y muestra
   `git log --oneline -1`.
8. **No hagas push.** Pregunta aparte si quiere subirlo; el push solo con un
   OK específico para el push.
