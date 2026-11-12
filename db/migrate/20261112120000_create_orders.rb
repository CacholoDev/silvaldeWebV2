class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      # A guest order has no user; it is linked to an account at checkout
      # or viewed through a signed link. Deleting the account (GDPR) only
      # unlinks the order: orders are never destroyed.
      t.references :user, null: true, foreign_key: { on_delete: :nullify }

      t.string :contact_name, null: false
      t.string :contact_email, null: false
      t.string :contact_phone
      t.string :pickup_store, null: false
      t.string :payment_method, null: false
      t.string :payment_status, null: false, default: "pending"

      t.timestamps
    end
  end
end
