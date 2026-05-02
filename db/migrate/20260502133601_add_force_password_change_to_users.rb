class AddForcePasswordChangeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :force_password_change, :boolean, default: false
  end
end
