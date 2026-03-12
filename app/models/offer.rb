class Offer < ApplicationRecord
  has_many :cover_letters, dependent: :destroy

  has_many :applications, dependent: :destroy
  has_many :chats, dependent: :destroy

  validates :title, presence: true, length: { minimum: 3 }
  validates :url, presence: true
  validates :description, presence: true, length: { minimum: 10 }

  # validates :cv, presence: true
end
