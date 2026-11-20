# Builds an order in a given state through the real AASM transitions, so the
# examples start from somewhere the state machine can really reach (the pickup
# branch hands the package over; the shipping branch delivers it).
module OrderStates
  EVENTS_TO_STATE = {
    "pending" => [],
    "confirmed" => [ :confirm ],
    "ready_for_pickup" => [ :confirm, :mark_ready ],
    "picked_up" => [ :confirm, :mark_ready, :mark_picked_up ],
    "shipped" => [ :confirm, :ship ],
    "delivered" => [ :confirm, :ship, :deliver ],
    "cancelled" => [ :cancel ]
  }.freeze

  def order_in(state, user: nil)
    traits = %w[shipped delivered].include?(state) ? [ :shipping ] : []
    order = create(:order, *traits, user: user)
    EVENTS_TO_STATE.fetch(state).each { |event| order.public_send("#{event}!") }
    order
  end
end

RSpec.configure do |config|
  config.include OrderStates
end
