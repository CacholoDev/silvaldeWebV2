FactoryBot.define do
  factory :order_status_change, class: "Orders::StatusChange" do
    order
    user { nil }
    from_state { "confirmed" }
    to_state { "ready_for_pickup" }
    manual { false }
  end
end
