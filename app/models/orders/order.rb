module Orders
  # A customer's order: who buys, where they pick it up and how they pay.
  # The order state machine (AASM) and its lines (Orders::OrderItem, with the
  # prices frozen at checkout) arrive in later slices; see docs/backend-plan.md.
  class Order < ApplicationRecord
    self.table_name = "orders"

    # Upper bounds match the varchar columns, so crafted input cannot overflow.
    MAX_NAME_LENGTH = 255
    MAX_EMAIL_LENGTH = 255
    MAX_PHONE_LENGTH = 30

    PICKUP_STORES = %w[bertamirans noia].freeze
    PAYMENT_METHODS = %w[bank_transfer pay_in_store].freeze
    PAYMENT_STATUSES = %w[pending paid refunded].freeze

    EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP
    PHONE_FORMAT = /\A\+?[\d\s\-()]{7,30}\z/

    belongs_to :user, class_name: "Users::User", optional: true

    validates :contact_name, presence: true
    validates :contact_name, length: { maximum: MAX_NAME_LENGTH }, allow_nil: true

    validates :contact_email, presence: true
    validates :contact_email, length: { maximum: MAX_EMAIL_LENGTH }, allow_nil: true
    validates :contact_email, format: { with: EMAIL_FORMAT }, allow_nil: true

    validates :contact_phone, length: { maximum: MAX_PHONE_LENGTH }, allow_nil: true
    validates :contact_phone, format: { with: PHONE_FORMAT }, allow_nil: true

    validates :pickup_store, presence: true
    validates :pickup_store, inclusion: { in: PICKUP_STORES }, allow_nil: true

    validates :payment_method, presence: true
    validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_nil: true

    validates :payment_status, presence: true
    validates :payment_status, inclusion: { in: PAYMENT_STATUSES }, allow_nil: true

    # A guest order has no account behind it: it is reached through the
    # signed link in its emails, never through a session-held id.
    def guest?
      user_id.nil?
    end

    def paid?
      payment_status == "paid"
    end
  end
end
