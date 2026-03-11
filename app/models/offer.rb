class Offer < ApplicationRecord
  has_many :applications
  has_many :chats
    has_many :cover_letters


  validates :title, presence: true, length: { minimum: 3 }
  validates :url, presence: true
  validates :description, presence: true, length: { minimum: 10 }

  # validates :cv, presence: true
end
