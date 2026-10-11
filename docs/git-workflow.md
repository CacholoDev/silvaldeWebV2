# Flujo de trabajo con git

Trabajamos por **features y ramas**: cada funcionalidad se desarrolla en su
propia rama y se integra en `main` cuando está terminada y validada. Nunca se
trabaja directamente sobre `main`, salvo documentación base o el commit de
publicación de una versión.

## Tipos de ramas

- `main`: rama estable. Siempre debe arrancar y pasar las validaciones.
- `feature/<nombre>`: funcionalidad nueva. Ej.: `feature/autenticacion`,
  `feature/catalogo-productos`, `feature/carrito`.
- `fix/<nombre>`: corrección de un error detectado en `main`.
- `chore/<nombre>`: tareas técnicas sin cambio funcional (dependencias,
  configuración).
- `docs/<nombre>`: cambios solo de documentación.

Nombres en minúsculas, con guiones, en español y descriptivos. Una rama = una
responsabilidad.

## Ciclo de una feature

1. Partir de `main` actualizada:

   ```bash
   git switch main && git pull
   git switch -c feature/<nombre>
   ```

2. Commits pequeños y frecuentes con los mensajes descritos abajo.
3. Antes de integrar, dejar el CI local en verde:

   ```bash
   bin/ci
   ```

   (Equivale a `bin/rails test`, `bin/rubocop`, `bin/brakeman`,
   `bin/bundler-audit` y el audit de importmap.)

4. Integrar en `main`. Si la feature completa una fase del
   [roadmap](./roadmap.md), seguir [versioning.md](./versioning.md) para
   publicar la nueva versión y su tag.
5. Borrar la rama ya integrada.

## Mensajes de commit

Formato [Conventional Commits](https://www.conventionalcommits.org/es/) en
español e imperativo:

- `feat: añade registro de clientes`
- `fix: corrige validación de email duplicado`
- `docs: actualiza roadmap con la fase de catálogo`
- `test: cubre autorización del panel admin`
- `refactor: extrae servicio de búsqueda de productos`
- `chore: actualiza gemas`

## Reglas

- Un commit = un cambio coherente. No mezclar refactors con features.
- No subir `.env`, credenciales ni datos reales (protegidos en `.gitignore`).
- Si una feature crece demasiado, dividirla en ramas más pequeñas antes de
  seguir añadiendo código.
- Los agentes no hacen commits, merges, push ni tags sin confirmación
  explícita del usuario.
