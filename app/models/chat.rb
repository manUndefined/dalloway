class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :offer

  has_many :messages, dependent: :destroy
  validates :title, presence: true, length: { minimum: 3 }
end
