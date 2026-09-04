class ItinerariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :require_itinerary, only: [:show, :edit, :update]

  def create
    system_prompt = <<~PROMPT
      You are TripGen AI, a helpful travel planning assistant.

      Your task is to create a realistic daily travel itinerary based on the user's trip information.

      Respect:
      - the trip dates
      - the user's budget
      - the travel style
      - the destination
      - the trip description

      Create practical activities with realistic times and estimated costs.

      Return ONLY valid JSON.
      Do not include Markdown.
      Do not include explanations outside the JSON.

      The JSON must have this structure:

      {
        "days": [
          {
            "day_number": 1,
            "date": "YYYY-MM-DD",
            "title": "Day title",
            "activities": [
              {
                "start_time": "09:00",
                "end_time": "11:00",
                "location": "Place name",
                "estimated_cost": 10.0
              }
            ]
          }
        ]
      }
    PROMPT

    chat = Chat.create!(model: "gpt-5-nano")

    chat.with_instructions(system_prompt)

    response = chat.ask(build_prompt)

    itinerary = JSON.parse(response.content)

    create_itinerary_records(itinerary)

    redirect_to trip_itinerary_path(@trip),
                notice: "Your itinerary has been generated!"
  rescue RubyLLM::RateLimitError
    create_demo_itinerary

    redirect_to trip_itinerary_path(@trip),
                notice: "Demo itinerary generated successfully!"
  rescue JSON::ParserError
    create_demo_itinerary

    redirect_to trip_itinerary_path(@trip),
                notice: "Demo itinerary generated successfully!"
  rescue StandardError => e
    Rails.logger.error "Itinerary generation failed: #{e.class}: #{e.message}"

    create_demo_itinerary

    redirect_to trip_itinerary_path(@trip),
                notice: "Demo itinerary generated successfully!"
  end

  def show
    @itinerary_days = @trip.itinerary_days.includes(:activities)
  end

  def edit
    @itinerary_days = @trip.itinerary_days.includes(:activities)
  end

  def update
    @itinerary_days = @trip.itinerary_days.includes(:activities)

    if update_activities
      redirect_to trip_itinerary_path(@trip),
                  notice: "Itinerary updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end

  # Without an itinerary there is nothing to show, edit or update. Rendering
  # those pages anyway leaves a trip looking like it still has an itinerary:
  # an empty travel-plan page with edit and delete buttons on it.
  def require_itinerary
    return if @trip.itinerary_days.exists?

    redirect_to trip_path(@trip)
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
      Travelling with: #{@trip.traveling_with}

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

  def create_demo_itinerary
    @trip.itinerary_days.destroy_all

    current_date = @trip.start_date
    day_number = 1

    while current_date <= @trip.end_date
      day = @trip.itinerary_days.create!(
        date: current_date,
        day_number: day_number,
        title: "Day #{day_number}"
      )

      day.activities.create!(
        user: current_user,
        start_time: Time.zone.parse("09:00"),
        end_time: Time.zone.parse("11:00"),
        location: "Main attraction",
        estimated_cost: 10
      )

      day.activities.create!(
        user: current_user,
        start_time: Time.zone.parse("12:00"),
        end_time: Time.zone.parse("14:00"),
        location: "Local restaurant",
        estimated_cost: 15
      )

      day.activities.create!(
        user: current_user,
        start_time: Time.zone.parse("15:00"),
        end_time: Time.zone.parse("18:00"),
        location: "City center",
        estimated_cost: 0
      )

      current_date += 1.day
      day_number += 1
    end
  end

  def update_activities
    @itinerary_days.all? do |day|
      day.activities.all? do |activity|
        activity.update(activity_params(activity))
      end
    end
  end

  def activity_params(activity)
    {
      start_time: params.dig(:activities, activity.id.to_s, :start_time),
      end_time: params.dig(:activities, activity.id.to_s, :end_time),
      location: params.dig(:activities, activity.id.to_s, :location),
      estimated_cost: params.dig(:activities, activity.id.to_s, :estimated_cost)
    }
  end
end
