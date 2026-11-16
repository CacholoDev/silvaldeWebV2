class RemoveUnitPriceCentsFromCartItems < ActiveRecord::Migration[8.1]
  def change
    # A cart line no longer stores a snapshot price: it always follows the
    # catalog. Only purchased orders (order_items) freeze a price.
    remove_column :cart_items, :unit_price_cents, :integer
  end
end
