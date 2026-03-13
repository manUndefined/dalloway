class AddSourceToOffers < ActiveRecord::Migration[8.1]
  def change
    add_column :offers, :source, :string, default: "manual"
  end
end
