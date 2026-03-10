class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :offer
  has_many :messages

end
