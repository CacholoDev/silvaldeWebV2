# frozen_string_literal: true

module SilvaldeWebV2
  # Versión vigente de la aplicación, cargada desde el archivo VERSION
  # (fuente única de verdad: no duplicarla en otros archivos).
  # Uso: SilvaldeWebV2::APP_VERSION — p. ej. en el footer del panel admin.
  # Proceso de publicación: docs/versioning.md. Historial: CHANGELOG.md.
  APP_VERSION = Rails.root.join("VERSION").read.strip.freeze
end
