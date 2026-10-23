class AddCommunicationsConsentToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :communications_consent, :boolean, null: false, default: false
  end
end
