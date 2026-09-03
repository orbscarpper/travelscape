class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip

  def index
    @chats = @trip.chats.order(created_at: :desc)
  end

  def create
    @chat = @trip.chats.create!(model: "gpt-5-nano")

    redirect_to trip_chat_path(@trip, @chat)
  end

  def show
    @chat = @trip.chats.find(params[:id])
    @messages = @chat.messages.order(created_at: :asc)
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end

  def system_prompt
    <<~PROMPT
      You are TripGen AI, a helpful travel planning assistant.

      You are helping a user plan their trip.

      Trip:
      Name: #{@trip.title}
      Description: #{@trip.description}
      Start date: #{@trip.start_date}
      End date: #{@trip.end_date}
      Budget: €#{@trip.budget}
      Travel style: #{@trip.travel_style}
      Travelling with: #{@trip.traveling_with}

      Give practical, realistic travel advice based on this trip context.

      Be concise and helpful.
    PROMPT
  end
end
