require "net/http"
require "uri"
require "json"

class ItinerariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip

  def create
  Rails.logger.info "========== ITINERARY CREATE CALLED =========="
  Rails.logger.info "Trip: #{@trip.id}"
  Rails.logger.info "Destination: #{@trip.destination}"
  Rails.logger.info "Dates: #{@trip.start_date} - #{@trip.end_date}"
  Rails.logger.info "Budget: #{@trip.budget}"
  Rails.logger.info "Travel style: #{@trip.travel_style}"
  Rails.logger.info "Traveling with: #{@trip.traveling_with}"

  system_prompt = <<~PROMPT
    You are TripGen AI, a travel planning assistant.

    Your job is to create a complete travel itinerary.

    IMPORTANT RULES:

    1. Return ONLY valid JSON.
    2. The top-level JSON object MUST contain a key called "days".
    3. "days" MUST be an array.
    4. Create exactly one day for every date of the trip.
    5. Each day MUST contain:
       - day_number
       - date
       - title
       - activities
    6. Each activity MUST contain:
       - start_time
       - end_time
       - location
       - estimated_cost
    7. Only recommend REAL places.
    8. Never use generic locations such as:
       - "City center"
       - "Main attraction"
       - "Local restaurant"
       - "Tourist area"
       - "Nearby bakery"
       - "your accommodation"
    9. Every location must be a specific real place.
    10. Include the city and country in every location.
    11. Respect the user's budget.
    12. Respect the user's travel style.
    13. Respect who the user is travelling with.
    14. Keep activities geographically close together when possible.
    15. Use realistic activity times.
    16. Use realistic estimated costs.

    The JSON MUST have exactly this structure:

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
              "location": "Louvre Museum, Paris, France",
              "estimated_cost": 17.0
            }
          ]
        }
      ]
    }
  PROMPT

  chat = Chat.create!(
    trip: @trip,
    model: "gpt-5-nano"
  )

  chat.with_instructions(system_prompt)

  response = chat.ask(build_prompt)

  Rails.logger.info "========== AI RESPONSE =========="
  Rails.logger.info response.content

  itinerary = JSON.parse(response.content)

  create_itinerary_records(itinerary)

  redirect_to trip_itinerary_path(@trip),
              notice: "Your AI itinerary has been generated!"

rescue RubyLLM::RateLimitError => e
  Rails.logger.error "========== OPENAI ERROR =========="
  Rails.logger.error e.message

  redirect_to trip_itinerary_path(@trip),
              alert: "OpenAI error: #{e.message}"

rescue JSON::ParserError => e
  Rails.logger.error "========== JSON ERROR =========="
  Rails.logger.error e.message

  redirect_to trip_itinerary_path(@trip),
              alert: "The AI returned invalid JSON."

rescue StandardError => e
  Rails.logger.error "========== ITINERARY ERROR =========="
  Rails.logger.error "#{e.class}: #{e.message}"
  Rails.logger.error e.backtrace.first(10).join("\n")

  redirect_to trip_itinerary_path(@trip),
              alert: "Itinerary generation failed: #{e.message}"
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

  def build_prompt
  number_of_days = (@trip.end_date - @trip.start_date).to_i + 1

  <<~PROMPT
    Create a #{number_of_days}-day travel itinerary.

    Trip information:

    Destination: #{@trip.destination}

    Trip name: #{@trip.title}

    Description: #{@trip.description}

    Start date: #{@trip.start_date}

    End date: #{@trip.end_date}

    Budget: €#{@trip.budget}

    Travel style: #{@trip.travel_style}

    Travelling with: #{@trip.traveling_with}

    Requirements:

    - Generate exactly #{number_of_days} days.
    - The first day must be #{@trip.start_date}.
    - The final day must be #{@trip.end_date}.
    - Every day must have several activities.
    - Every activity must be a real place.
    - Every location must include the city and country.
    - Do not use generic locations.
    - Keep the total cost appropriate for the €#{@trip.budget} budget.
    - Follow the #{@trip.travel_style} travel style.
    - Make activities appropriate for #{@trip.traveling_with}.
    - Keep nearby activities together geographically.

    VERY IMPORTANT:

    Return ONLY this JSON structure:

    {
      "days": [
        {
          "day_number": 1,
          "date": "#{@trip.start_date}",
          "title": "Example day title",
          "activities": [
            {
              "start_time": "09:00",
              "end_time": "11:00",
              "location": "Real Place, #{@trip.destination}",
              "estimated_cost": 10.0
            }
          ]
        }
      ]
    }

    Do not return:
    - "city"
    - "budget_eur"
    - "itinerary"
    - "transport"

    The ONLY top-level key should be "days".
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
        location = activity.fetch("location")

        coordinates = geocode_location(location)

        itinerary_day.activities.create!(
          user: current_user,
          start_time: Time.zone.parse(activity.fetch("start_time")),
          end_time: Time.zone.parse(activity.fetch("end_time")),
          location: location,
          latitude: coordinates&.first,
          longitude: coordinates&.last,
          estimated_cost: activity.fetch("estimated_cost")
        )
      end
    end
  end

  def geocode_location(location)
    return nil if location.blank?

    url = URI("https://api.mapbox.com/search/geocode/v6/forward")

    params = {
      q: location,
      access_token: ENV.fetch("MAPBOX_API_KEY"),
      limit: 1
    }

    url.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(url)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Mapbox error: #{response.code}"
      return nil
    end

    data = JSON.parse(response.body)

    feature = data["features"]&.first

    return nil unless feature

    longitude, latitude = feature["geometry"]["coordinates"]

    [latitude, longitude]
  rescue StandardError => e
    Rails.logger.error "Geocoding failed for #{location}: #{e.message}"
    nil
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
