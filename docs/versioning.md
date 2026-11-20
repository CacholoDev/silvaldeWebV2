# Versionado de Silvalde Web

La web se mantiene con un esquema tipo [Semantic Versioning](https://semver.org/lang/es/):
`MAYOR.MENOR.PARCHE`.

- **MAYOR**: cambios incompatibles o reestructuraciones grandes.
- **MENOR**: fases grandes del [roadmap](./roadmap.md) (p. ej. pedidos,
  panel de administración, envío a domicilio).
- **PARCHE**: **mini versiones** — mejoras pequeñas y funcionalidad a escala
  de la fase en curso (p. ej. `0.6.1`, `0.6.5`), no solo arreglos de errores.
  Acordado con el usuario el 2026-11-20 para entregar valor poco a poco sin
  esperar a la fase grande (ejemplo real: la `0.6.1`, métricas amplias sobre
  el panel de la `0.6.0`).

Mientras la tienda no esté en producción se trabaja en `0.x`: cada fase
completada sube el número del medio y las mini versiones suman en el tercero.
La `1.0.0` será el lanzamiento público de la tienda; a partir de ahí se
respeta SemVer estricto (un parche solo contiene arreglos).

## Dónde vive la versión

| Lugar | Para qué |
| --- | --- |
| `VERSION` | Archivo de texto con la versión actual. **Fuente única de verdad.** |
| `config/initializers/version.rb` | Carga `VERSION` en la constante `SilvaldeWebV2::APP_VERSION` para usarla dentro de la app (p. ej. mostrarla en el footer del panel admin). |
| `CHANGELOG.md` | Historial legible de cambios por versión. |
| Tags de git (`v0.1.0`) | Marcan el estado exacto del código en cada versión publicada. |

## Cómo publicar una nueva versión

1. Al terminar la versión y antes de abrir su pull request, el usuario lanza
   el code review de versión: `/project-review version` (ver
   [agent-tooling.md](./agent-tooling.md)) o, si no está disponible, con las
   skills de superpowers `requesting-code-review` y `receiving-code-review`,
   usando las reglas de `AGENTS.md`; corregir o documentar los hallazgos
   antes de seguir.
2. Asegurarse de que `main` está verde: `bin/ci` (o, como mínimo,
   `bundle exec rspec`, `bin/rubocop`, `bin/brakeman` y `bin/bundler-audit`).
3. Actualizar `CHANGELOG.md`: mover lo acumulado en «Sin publicar» a la nueva
   versión con su fecha.
4. Actualizar el archivo `VERSION` (solo eso: la app lo lee sola).
5. Commit `chore: publica vX.Y.Z`: directamente en `main` o, mejor, como
   último commit del PR que cierra la versión (así pasa por el CI de GitHub).
6. Con ese commit ya en `main`, crear el tag y subirlo junto con la rama:

   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin main --follow-tags
   ```

No se sube la versión dentro de una rama `feat/*`: la versión se asigna al
integrar en `main`. Los agentes no hacen commits, merges, push ni tags sin
confirmación explícita del usuario.
