# Seeds for development. Idempotent: re-running db:seed is safe.

admin_email = ENV["ADMIN_EMAIL"].to_s.strip.downcase
admin_password = ENV["ADMIN_PASSWORD"].to_s

if admin_email.empty? || admin_password.empty?
  Rails.logger.warn "[seed] ADMIN_EMAIL or ADMIN_PASSWORD missing; skipping admin user."
else
  admin = User.find_or_initialize_by(email_address: admin_email)
  admin.name ||= "Administrador"
  admin.role = :admin
  admin.password = admin_password if admin.new_record? || ENV["ADMIN_RESET_PASSWORD"] == "1"
  # Admin created by seed is considered pre-confirmed so the user can sign in
  # immediately in dev. In production, set up a real confirmation flow.
  admin.confirmed_at ||= Time.current
  admin.save!
  Rails.logger.info "[seed] admin user ready: #{admin.email_address}"
end
