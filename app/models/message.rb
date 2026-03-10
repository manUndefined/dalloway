class Message < ApplicationRecord
  belongs_to :chat
  validates :content, presence: true, length: { minimum: 1 }

  validates :role,
            presence: true,
            inclusion: { in: %w[user assistant system] }
end
