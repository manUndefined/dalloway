class AddJobTypeAndExperienceLevelToOffers < ActiveRecord::Migration[8.1]
  def change
    add_column :offers, :job_type, :string
    add_column :offers, :experience_level, :string
  end
end
