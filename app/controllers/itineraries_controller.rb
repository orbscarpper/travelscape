class ItinerariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip

  def create
    @itinerary_day = @trip.itinerary_days.create!(
      date: @trip.start_date,
      day_number: 1,
      title: "Day 1"
    )

    @itinerary_day.activities.create!(
      user: current_user,
      start_time: "09:00",
      end_time: "11:00",
      location: "Explore the city",
      estimated_cost: 0
    )

    redirect_to trip_itinerary_path(@trip)
  end

  def show
    @itinerary_days = @trip.itinerary_days.includes(:activities)
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end
end
