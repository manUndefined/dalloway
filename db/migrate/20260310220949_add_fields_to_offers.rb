class AddFieldsToOffers < ActiveRecord::Migration[8.1]
  def change
    add_column :offers, :city, :string
    add_column :offers, :domain, :string
    add_column :offers, :salary, :integer
  end
end
