class AddStateAndDeliveryMethodToOrders < ActiveRecord::Migration[8.1]
  def change
    # The package state machine (AASM drives it in Orders::Order); the money
    # lives in payment_status, not here. "pending" is the safe default, the
    # model upgrades pay-in-store orders to "confirmed" on creation.
    add_column :orders, :state, :string, null: false, default: "pending", limit: 20

    # "pickup" (Bertamirans or Noia) or "shipping" (home delivery, whose
    # checkout arrives in v0.7.0); see docs/roadmap.md.
    add_column :orders, :delivery_method, :string, null: false, default: "pickup", limit: 20

    # Shipping orders have no pickup store.
    change_column_null :orders, :pickup_store, true

    # Defence in depth: the model validations are the first line, but the
    # database also refuses unknown states, unknown delivery methods and a
    # pairing that contradicts itself (a shipping order with a pickup store,
    # or a pickup order without one).
    add_check_constraint :orders,
                         "state IN ('pending','confirmed','ready_for_pickup','picked_up','shipped','delivered','cancelled')",
                         name: "orders_state_values"
    add_check_constraint :orders, "delivery_method IN ('pickup','shipping')",
                         name: "orders_delivery_method_values"
    add_check_constraint :orders,
                         "(delivery_method = 'pickup' AND pickup_store IS NOT NULL) OR (delivery_method = 'shipping' AND pickup_store IS NULL)",
                         name: "orders_pickup_store_matches_delivery"
  end
end
