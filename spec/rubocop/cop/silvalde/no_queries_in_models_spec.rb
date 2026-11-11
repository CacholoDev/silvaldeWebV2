require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../../lib/rubocop/cop/silvalde"

RSpec.describe RuboCop::Cop::Silvalde::NoQueriesInModels, :config do
  include RuboCop::RSpec::ExpectOffense

  it "flags scopes" do
    expect_offense(<<~RUBY)
      class Session < ApplicationRecord
        scope :active, -> { where("expires_at > ?", Time.current) }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Models must not define `scope`. Move the query to `<Context>::Search`.
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Models must not query (`where`). Move the query to `<Context>::Search`.
      end
    RUBY
  end

  it "flags query methods on the class itself" do
    expect_offense(<<~RUBY)
      class Product < ApplicationRecord
        def self.featured
          where(featured: true)
          ^^^^^^^^^^^^^^^^^^^^^ Models must not query (`where`). Move the query to `<Context>::Search`.
        end
      end
    RUBY
  end

  it "allows associations, validations with a uniqueness scope and own-state methods" do
    expect_no_offenses(<<~RUBY)
      class CartItem < ApplicationRecord
        belongs_to :cart
        validates :variant_id, uniqueness: { scope: :cart_id }

        def subtotal_cents
          quantity * unit_price_cents
        end
      end
    RUBY
  end
end
