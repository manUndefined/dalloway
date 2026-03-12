class AddPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :preferred_job_type, :string
    add_column :users, :preferred_salary, :integer
    add_column :users, :preferred_city, :string
    add_column :users, :preferred_experience_level, :string
    add_column :users, :preferred_sector, :string
  end
end
