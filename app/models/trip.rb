class Trip < ApplicationRecord
  belongs_to :user

  validates :title, :start_date, :end_date, :budget, presence: true
end
