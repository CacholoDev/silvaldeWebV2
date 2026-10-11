# Changelog

Todos los cambios destacables de Silvalde Web se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y el versionado sigue [SemVer](https://semver.org/lang/es/). La versión
vigente está en el archivo `VERSION` y el proceso de publicación en
`docs/versioning.md`.

Tipos de cambio: `Añadido`, `Cambiado`, `Obsoleto`, `Eliminado`,
`Corregido`, `Seguridad`.

## [Sin publicar]

## [0.1.0] - 2026-10-11

### Añadido

- Scaffold inicial de Rails 8.1 con Ruby 4.0.7, MySQL 8.0 (Docker Compose),
  Tailwind CSS, Hotwire (Turbo/Stimulus) e Importmap.
- Documentación base del proyecto y de agentes: `README.md`, `AGENTS.md` y
  `AGENTS.full.md`.
- Control de versiones: SemVer, archivo `VERSION` como fuente única de verdad
  (expuesta en la app como `SilvaldeWebV2::APP_VERSION`), este changelog y
  proceso de publicación en `docs/versioning.md`.
- Flujo de trabajo por ramas y Conventional Commits en
  `docs/git-workflow.md`, y plan de fases en `docs/roadmap.md`.

[Sin publicar]: https://github.com/CacholoDev/silvaldeWebV2/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/CacholoDev/silvaldeWebV2/releases/tag/v0.1.0
