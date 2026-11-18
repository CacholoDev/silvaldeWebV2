class CreateOrderStatusChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :order_status_changes do |t|
      t.references :order, null: false, foreign_key: true

      # Who moved it: nil means the system did (e.g. a pay-in-store order
      # being born confirmed).
      t.references :user, foreign_key: true

      # nil origin records the birth of the order (created in to_state).
      t.string :from_state, limit: 20
      t.string :to_state, null: false, limit: 20

      # A forced move through the admin master key (which may move any state
      # by hand but never cancel an already delivered or picked-up order).
      t.boolean :manual, null: false, default: false

      t.timestamps
    end

    # Defence in depth: the model validations are the first line, but the
    # database also refuses states outside the Orders::Order machine.
    add_check_constraint :order_status_changes,
                         "to_state IN ('pending','confirmed','ready_for_pickup','picked_up','shipped','delivered','cancelled')",
                         name: "order_status_changes_to_state_values"
    add_check_constraint :order_status_changes,
                         "from_state IS NULL OR from_state IN ('pending','confirmed','ready_for_pickup','picked_up','shipped','delivered','cancelled')",
                         name: "order_status_changes_from_state_values"
  end
end
