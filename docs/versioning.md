# Versionado de Silvalde Web

La web se mantiene con [Semantic Versioning](https://semver.org/lang/es/):
`MAYOR.MENOR.PARCHE`.

- **MAYOR**: cambios incompatibles o reestructuraciones grandes.
- **MENOR**: funcionalidades nuevas compatibles (una feature completada suele
  ser un menor).
- **PARCHE**: correcciones de errores.

Mientras la tienda no esté en producción se trabaja en `0.x`: cada fase del
[roadmap](./roadmap.md) completada sube la versión menor. La `1.0.0` será el
lanzamiento público de la tienda.

## Dónde vive la versión

| Lugar | Para qué |
| --- | --- |
| `VERSION` | Archivo de texto con la versión actual. **Fuente única de verdad.** |
| `config/initializers/version.rb` | Carga `VERSION` en la constante `SilvaldeWebV2::APP_VERSION` para usarla dentro de la app (p. ej. mostrarla en el footer del panel admin). |
| `CHANGELOG.md` | Historial legible de cambios por versión. |
| Tags de git (`v0.1.0`) | Marcan el estado exacto del código en cada versión publicada. |

## Cómo publicar una nueva versión

1. Asegurarse de que `main` está verde: `bin/ci` (o, como mínimo,
   `bin/rails test`, `bin/rubocop`, `bin/brakeman` y `bin/bundler-audit`).
2. Actualizar `CHANGELOG.md`: mover lo acumulado en «Sin publicar» a la nueva
   versión con su fecha.
3. Actualizar el archivo `VERSION` (solo eso: la app lo lee sola).
4. Commit en `main`: `chore: publica vX.Y.Z`.
5. Crear el tag y subirlo junto con la rama:

   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin main --follow-tags
   ```

No se sube la versión dentro de una rama `feat/*`: la versión se asigna al
integrar en `main`. Los agentes no hacen commits, merges, push ni tags sin
confirmación explícita del usuario.
