class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.integer :role, null: false, default: 0
      t.string :name

      t.datetime :confirmed_at
      t.string :confirmation_digest
      t.datetime :confirmation_sent_at

      t.timestamps
    end

    # Case-insensitive uniqueness: the index stores the lowercased value so
    # "Foo@bar.com" and "foo@bar.com" cannot coexist. The model normalizes
    # email_address to downcase before writing. MySQL 8 needs the
    # functional-index expression wrapped in parentheses.
    add_index :users, "(lower(email_address))", unique: true, name: "index_users_on_lower_email_address"
  end
end
