# Flujo de trabajo con git

Trabajamos por **features y ramas**: cada funcionalidad se desarrolla en su
propia rama y se integra en `main` cuando está terminada y validada. Nunca se
trabaja directamente sobre `main`, salvo documentación base o el commit de
publicación de una versión.

## Tipos de ramas

- `main`: rama estable. Siempre debe arrancar y pasar las validaciones.
- `feat/<name>`: funcionalidad nueva. Ej.: `feat/authentication`,
  `feat/catalog`, `feat/cart`.
- `fix/<name>`: corrección de un error detectado en `main`.
- `chore/<name>`: tareas técnicas sin cambio funcional (dependencias,
  configuración).
- `docs/<name>`: cambios solo de documentación.

Nombres en minúsculas, con guiones, **en inglés** y descriptivos. Una rama =
una responsabilidad.

## Ciclo de una feature

1. Partir de `main` actualizada:

   ```bash
   git switch main && git pull
   git switch -c feat/<name>
   ```

2. Commits pequeños y frecuentes con los mensajes descritos abajo.
3. Antes de integrar, dejar el CI local en verde:

   ```bash
   bin/ci
   ```

   (Equivale a `bundle exec rspec`, `bin/rubocop`, `bin/brakeman`,
   `bin/bundler-audit` y el audit de importmap.)

4. Integrar en `main`. Si la feature completa una fase del
   [roadmap](./roadmap.md), seguir [versioning.md](./versioning.md) para
   publicar la nueva versión y su tag.
5. Borrar la rama ya integrada.

## PRs por bloque y commits por funcionalidad

Las versiones grandes se dividen en **bloques** en
[`backend-plan.md`](./backend-plan.md) (p. ej. la v0.5.0 de pedidos: A
modelos y estados, B checkout, C emails y detalle) y **cada bloque tiene su
rama y su PR** (en draft hasta cerrarlo): al entrar en la PR se ven los
commits y se entiende qué hace cada cual.

- **Un commit = una funcionalidad**, no un slice: cada `feat`, cada `fix`,
  cada documento… va en su propio commit, como en un equipo de trabajo. Un
  slice puede dar varios commits.
- **Los cambios se van acumulando durante el slice** y se proponen al
  cerrarlo: el agente lista los commits pertinentes y espera el OK.
- **La PR del bloque** se abre al empezar el bloque, o antes si hace falta
  compartir o respaldar el trabajo (p. ej. cambiar de PC: basta con `git
  pull` de la rama en la otra máquina). Se marca *ready* cuando el bloque
  está terminado y `bin/ci` pasa, y la merge lleva su confirmación aparte.

## Mensajes de commit

Formato [Conventional Commits](https://www.conventionalcommits.org/) con
`type` y `scope` en inglés y resumen en imperativo también en inglés:

- `feat: add user signup`
- `fix: handle duplicate email validation`
- `docs: update roadmap with the catalog phase`
- `test: cover admin panel authorization`
- `refactor: extract product search service`
- `chore: bump gems`

## Confirmación de commits con agentes

El agente propone el mensaje y la lista de archivos que entran (sin pegar el
diff: se revisa en el panel Source Control de VS Code) y espera un OK.
Cualquier afirmativa natural vale («dale», «ok», «venga», «vamos», «sí»…).
El push siempre es una confirmación aparte. Claude Code y opencode piden
confirmación para `git commit`, `git push`, `git merge` y `git tag` por
configuración (ver [agent-tooling.md](./agent-tooling.md)). Atajo: skill
`/commit`.

## Ramas de Dependabot

Dependabot abre cada semana un PR agrupado para las subidas *minor* y *patch*
de gemas y otro para GitHub Actions; las *major* llegan sueltas. Se revisan
como cualquier PR: CI en verde y, si son majors, leer el changelog de la gema.
Al cerrar o mergear un PR, borra su rama `dependabot/*`.

## Reglas

- Un commit = un cambio coherente. No mezclar refactors con features.
- No subir `.env`, credenciales ni datos reales (protegidos en `.gitignore`).
- Si una feature crece demasiado, dividirla en ramas más pequeñas antes de
  seguir añadiendo código.
- Los agentes no hacen commits, merges, push ni tags sin confirmación
  explícita del usuario.
