class CreateCoverLetters < ActiveRecord::Migration[8.1]
  def change
    create_table :cover_letters do |t|
      t.text :content
      t.string :details
      t.references :user, null: false, foreign_key: true
      t.references :offer, null: false, foreign_key: true

      t.timestamps
    end

    remove_column :applications, :cover_letter, :string
  end
end
