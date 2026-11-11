# System specs drive a real browser (headless Chrome via Selenium) so Turbo
# Streams and Stimulus run as they do for the shopper.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ]
  end
end
