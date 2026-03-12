class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :city, :string
    add_column :users, :domain, :string
    add_column :users, :job_type, :string
    add_column :users, :experience_level, :string
    add_column :users, :salary, :integer
  end
end
