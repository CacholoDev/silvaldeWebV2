module Carts
  # Shopping cart. A guest cart has no user (nil); a customer cart belongs to
  # one. The items live in Carts::CartItem.
  class Cart < ApplicationRecord
    self.table_name = "carts"

    # Retention cap: a cart expires after six months without activity (any
    # change to its items counts as activity, see CartItem's touch: true).
    # The queries live in Carts::Search; only #expired? stays here.
    MAX_INACTIVITY = 6.months

    # The user model lives in another context (Users::User), so the class must
    # be spelled out: inside Carts, Ruby would look for Carts::User otherwise.
    belongs_to :user, class_name: "Users::User", optional: true

    has_many :cart_items, dependent: :destroy, inverse_of: :cart

    def expired?
      updated_at < MAX_INACTIVITY.ago
    end
  end
end
