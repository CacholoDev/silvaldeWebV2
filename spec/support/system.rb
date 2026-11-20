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

# Chrome 158 (installed by the system auto-updater on 2026-11-20) rejects the
# wildcard origin that Capybara 3.40 sends when resetting the session:
# Storage.clearDataForOrigin with origin: '*' fails with "* is not a valid
# URL", so every system example errored at teardown although its body passed.
# Capybara 3.40.0 is still the latest release, so we rewrite that single call
# to clear the origin of the app under test — the only origin these specs
# ever visit. Drop this patch once a Capybara release fixes the wildcard.
module ChromeStorageOriginFix
  def execute_cdp(cmd, params = {})
    if cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"
      params = params.merge(origin: Capybara.current_session.server.base_url)
    end
    super
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeStorageOriginFix)
