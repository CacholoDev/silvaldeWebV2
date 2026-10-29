class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false, limit: 150
      t.string :slug, null: false, limit: 200
      t.text :description, null: false
      t.integer :price_cents, null: false

      t.timestamps
    end

    add_index :products, :name, unique: true
    add_index :products, :slug, unique: true
  end
end
