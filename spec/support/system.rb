# System specs drive a real browser (headless Chrome via Selenium) so Turbo
# Streams and Stimulus run as they do for the shopper.
#
# --no-sandbox disables Chrome's own sandbox for the test browser only: it
# cannot start on Ubuntu 23.10+ where AppArmor restricts unprivileged user
# namespaces ("No usable sandbox!" and the session dies). The browser only
# visits the local app under test, so nothing is exposed.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ] do |options|
      options.add_argument("--no-sandbox")
    end
  end
end
