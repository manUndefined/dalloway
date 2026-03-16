class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :offer

  has_many :messages, dependent: :destroy
  validates :title, presence: true, length: { minimum: 3 }
  def user_messages_count
    messages.where(role: "user").count
  end
end
