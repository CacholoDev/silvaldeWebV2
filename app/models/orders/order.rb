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

    # Public number the customer uses to reference the order ("your order
    # SV-K7M2QX"): random and unique, never the sequential id, which would
    # leak how many orders the shop has processed.
    NUMBER_FORMAT = /\ASV-[2-9A-HJ-NP-Z]{6}\z/
    # 32 chars without 0/O/1/I so the number can be dictated over the phone
    # without confusions (32**6 ≈ 1.07 billion possible numbers).
    NUMBER_ALPHABET = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
    NUMBER_BODY_LENGTH = 6

    belongs_to :user, class_name: "Users::User", optional: true

    has_many :order_items, dependent: :destroy, inverse_of: :order

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

    validates :number, presence: true
    validates :number, format: { with: NUMBER_FORMAT }, allow_nil: true
    validates :number, uniqueness: true

    before_validation :assign_number, on: :create

    # A fresh public number: SV- plus six random characters of
    # NUMBER_ALPHABET, taken from SecureRandom (never from the id).
    def self.generate_number
      body = Array.new(NUMBER_BODY_LENGTH) { NUMBER_ALPHABET[SecureRandom.random_number(NUMBER_ALPHABET.length)] }.join
      "SV-#{body}"
    end

    # A guest order has no account behind it: it is reached through the
    # signed link in its emails, never through a session-held id.
    def guest?
      user_id.nil?
    end

    def paid?
      payment_status == "paid"
    end

    private

    # Gives the order its public number on creation; an explicitly assigned
    # number is kept as-is (tests and future imports may set one).
    def assign_number
      self.number = self.class.generate_number if number.blank?
    end
  end
end
