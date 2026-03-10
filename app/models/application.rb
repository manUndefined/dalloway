class Application < ApplicationRecord
  belongs_to :user
  belongs_to :offer
  validates :cover_letter, presence: true, length: { minimum: 20 }

  validates :status,
            presence: true,
            inclusion: { in: %w[pending accepted rejected] }
end
