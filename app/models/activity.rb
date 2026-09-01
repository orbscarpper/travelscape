class Activity < ApplicationRecord
  belongs_to :itinerary_day
  belongs_to :user
end
