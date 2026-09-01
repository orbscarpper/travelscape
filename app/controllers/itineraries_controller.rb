class ItinerariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip

  def create
    system_prompt = File.read(
      Rails.root.join("app/prompts/itinerary_system_prompt.txt")
    )

    chat = Chat.create!(model: "gpt-5-nano")

    chat.with_instructions(system_prompt)

    response = chat.ask(build_prompt)

    itinerary = JSON.parse(response.content)

    create_itinerary_records(itinerary)

    redirect_to trip_itinerary_path(@trip),
                notice: "Your itinerary has been generated!"
  rescue RubyLLM::RateLimitError
    redirect_to trip_path(@trip),
                alert: "AI is currently unavailable. Please check the API credits."
  rescue JSON::ParserError
    redirect_to trip_path(@trip),
                alert: "AI returned an invalid itinerary. Please try again."
  end

  def show
    @itinerary_days = @trip.itinerary_days.includes(:activities)
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end

  def build_prompt
    number_of_days = (@trip.end_date - @trip.start_date).to_i + 1

    <<~PROMPT
      Create a #{number_of_days}-day itinerary for this trip.

      Trip name: #{@trip.title}
      Description: #{@trip.description}
      Start date: #{@trip.start_date}
      End date: #{@trip.end_date}
      Budget: €#{@trip.budget}
      Travel style: #{@trip.travel_style}

      Generate one itinerary day for each date from the start date
      to the end date.

      Keep the total estimated cost appropriate for the trip budget.
      Include several useful activities per day.
    PROMPT
  end

  def create_itinerary_records(itinerary)
    @trip.itinerary_days.destroy_all

    itinerary.fetch("days").each do |day|
      itinerary_day = @trip.itinerary_days.create!(
        date: Date.parse(day.fetch("date")),
        day_number: day.fetch("day_number"),
        title: day.fetch("title")
      )

      day.fetch("activities").each do |activity|
        itinerary_day.activities.create!(
          user: current_user,
          start_time: Time.zone.parse(activity.fetch("start_time")),
          end_time: Time.zone.parse(activity.fetch("end_time")),
          location: activity.fetch("location"),
          estimated_cost: activity.fetch("estimated_cost")
        )
      end
    end
  end
end
