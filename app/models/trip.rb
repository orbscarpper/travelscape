class Trip < ApplicationRecord
  belongs_to :user

  has_many :itinerary_days, dependent: :destroy

  validates :title, :start_date, :end_date, :budget, presence: true
end
