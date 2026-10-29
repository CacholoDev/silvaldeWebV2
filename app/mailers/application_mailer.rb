class ApplicationMailer < ActionMailer::Base
  # Sender configured via environment; the default is a placeholder that
  # must be replaced before deploying (see README, "Variables de entorno").
  default from: ENV.fetch("MAILER_FROM", "from@example.com")
  layout "mailer"
end
