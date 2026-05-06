class AddDocumentFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :cnh_number, :string
    add_column :users, :cnh_category, :string
    add_column :users, :cnh_expiration_date, :date
  end
end
