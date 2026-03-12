class Offer < ApplicationRecord
<<<<<<< offerpage
  has_many :applications
  has_many :chats
    has_many :cover_letters

=======
  has_many :applications, dependent: :destroy
  has_many :chats, dependent: :destroy
>>>>>>> main

  validates :title, presence: true, length: { minimum: 3 }
  validates :url, presence: true
  validates :description, presence: true, length: { minimum: 10 }

  # validates :cv, presence: true
end
