class CreateVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true, index: false
      t.string :name, null: false, limit: 100
      t.integer :stock, null: false, default: 0
      t.integer :price_cents

      t.timestamps
    end

    add_index :variants, [ :product_id, :name ], unique: true
  end
end
