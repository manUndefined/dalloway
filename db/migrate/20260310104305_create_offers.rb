class CreateOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :offers do |t|
      t.string :title
      t.string :url
      t.string :description

      t.timestamps
    end
  end
end
