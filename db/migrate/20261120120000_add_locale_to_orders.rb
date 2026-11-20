class AddLocaleToOrders < ActiveRecord::Migration[8.1]
  def change
    # The language the customer used at checkout: its emails are sent in it.
    # "es" is the shop's fallback and the default for existing rows.
    add_column :orders, :locale, :string, null: false, default: "es", limit: 5

    # Defence in depth: the model validates it too, but the database also
    # refuses unknown languages.
    add_check_constraint :orders, "locale IN ('es','gl','en')", name: "orders_locale_values"
  end
end
