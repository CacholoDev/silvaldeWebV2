class CreatePasswordResetTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :password_reset_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest
      t.datetime :expires_at
      t.datetime :used_at

      t.timestamps
    end
    add_index :password_reset_tokens, :token_digest, unique: true
  end
end
