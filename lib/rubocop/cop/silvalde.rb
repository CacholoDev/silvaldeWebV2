# Project cops: they turn the architecture rules of AGENTS.md into checks
# that `bin/rubocop` (and therefore `bin/ci` and GitHub Actions) enforce.
require_relative "silvalde/no_active_record_in_controllers"
require_relative "silvalde/no_queries_in_models"
