class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      # Nullable: a guest cart has no user, only customer carts do.
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
