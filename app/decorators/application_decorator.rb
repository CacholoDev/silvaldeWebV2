require "delegate"

# Base decorator: presentation formatting for views. A decorator wraps a
# record, never mutates persistence and never queries the database
# (see AGENTS.full.md, "Decorators y presentación").
class ApplicationDecorator < SimpleDelegator
  private

  def euros(cents)
    ActiveSupport::NumberHelper.number_to_currency(cents / 100.0)
  end
end
