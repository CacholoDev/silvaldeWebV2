module Orders
  # A customer's order: who buys, how they get it (pickup in Bertamirans or
  # Noia; home shipping from v0.7.0) and how they pay. The package travels
  # the AASM state machine below; the money lives in payment_status, so both
  # can differ (ready for pickup and still pending payment). Its lines
  # (Orders::OrderItem) carry the prices frozen at checkout.
  class Order < ApplicationRecord
    self.table_name = "orders"

    include AASM

    # Upper bounds match the varchar columns, so crafted input cannot overflow.
    MAX_NAME_LENGTH = 255
    MAX_EMAIL_LENGTH = 255
    MAX_PHONE_LENGTH = 30

    PICKUP_STORES = %w[bertamirans noia].freeze
    PAYMENT_METHODS = %w[bank_transfer pay_in_store].freeze
    PAYMENT_STATUSES = %w[pending paid refunded].freeze
    DELIVERY_METHODS = %w[pickup shipping].freeze
    LOCALES = %w[es gl en].freeze

    # What happens to the package (not to the money: payment_status covers
    # that). See docs/roadmap.md for the decision and the transition table.
    STATES = %w[pending confirmed ready_for_pickup picked_up shipped delivered cancelled].freeze

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
    has_many :status_changes, dependent: :destroy, inverse_of: :order

    validates :contact_name, presence: true
    validates :contact_name, length: { maximum: MAX_NAME_LENGTH }, allow_nil: true

    validates :contact_email, presence: true
    validates :contact_email, length: { maximum: MAX_EMAIL_LENGTH }, allow_nil: true
    validates :contact_email, format: { with: EMAIL_FORMAT }, allow_nil: true

    validates :contact_phone, length: { maximum: MAX_PHONE_LENGTH }, allow_nil: true
    validates :contact_phone, format: { with: PHONE_FORMAT }, allow_nil: true

    # A pickup order is collected in one of the shops; a shipping order has
    # no pickup store at all (home delivery arrives in v0.7.0).
    validates :pickup_store, presence: true, if: :pickup?
    validates :pickup_store, absence: true, if: :shipping?
    validates :pickup_store, inclusion: { in: PICKUP_STORES }, allow_nil: true

    validates :payment_method, presence: true
    validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_nil: true

    validates :payment_status, presence: true
    validates :payment_status, inclusion: { in: PAYMENT_STATUSES }, allow_nil: true

    validates :state, presence: true
    validates :state, inclusion: { in: STATES }, allow_nil: true

    validates :delivery_method, presence: true
    validates :delivery_method, inclusion: { in: DELIVERY_METHODS }, allow_nil: true

    # The language the customer used at checkout: its emails are sent in it.
    validates :locale, presence: true
    validates :locale, inclusion: { in: LOCALES }, allow_nil: true

    validates :number, presence: true
    validates :number, format: { with: NUMBER_FORMAT }, allow_nil: true
    validates :number, uniqueness: true

    before_validation :normalize_blank_phone
    before_validation :assign_initial_state, on: :create
    before_validation :assign_number, on: :create

    # The package state machine. Staff never toggles states by hand: they
    # report business events ("the transfer landed", "prepared", "handed
    # over") and the machine moves, refusing anything else (see the invalid
    # transition specs and docs/roadmap.md).
    aasm column: :state do
      state :pending, initial: true
      state :confirmed
      state :ready_for_pickup
      state :picked_up
      state :shipped
      state :delivered
      state :cancelled

      # The transfer/Bizum landed (a pay-in-store order is born confirmed).
      event :confirm do
        transitions from: :pending, to: :confirmed
      end

      event :mark_ready do
        transitions from: :confirmed, to: :ready_for_pickup, guard: :pickup?
      end

      event :mark_picked_up do
        transitions from: :ready_for_pickup, to: :picked_up
      end

      # Home delivery (v0.7.0). The guards keep the two branches from ever
      # mixing: a pickup order can never be shipped and vice versa.
      event :ship do
        transitions from: :confirmed, to: :shipped, guard: :shipping?
      end

      event :deliver do
        transitions from: :shipped, to: :delivered
      end

      # Only before the package is prepared or shipped: prepared, shipped,
      # picked up and delivered are final.
      event :cancel do
        transitions from: [ :pending, :confirmed ], to: :cancelled
      end
    end

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

    # How the customer gets the package: collected in a shop or shipped.
    def pickup?
      delivery_method == "pickup"
    end

    def shipping?
      delivery_method == "shipping"
    end

    private

    # The form sends "" for the optional phone; store nil instead so the
    # allow_nil validations mean what they say and the blank is not kept.
    def normalize_blank_phone
      self.contact_phone = nil if contact_phone.blank?
    end

    # A pay-in-store order has nothing to verify (it pays on pickup), so it
    # starts confirmed and ready to prepare; a bank-transfer order waits
    # pending until the money lands.
    def assign_initial_state
      self.state = "confirmed" if payment_method == "pay_in_store" && state == "pending"
    end

    # Gives the order its public number on creation; an explicitly assigned
    # number is kept as-is (tests and future imports may set one).
    def assign_number
      self.number = self.class.generate_number if number.blank?
    end
  end
end
