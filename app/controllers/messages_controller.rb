class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip
  before_action :set_chat

  def create
    content = params[:content].to_s.strip

    if content.blank?
      redirect_to trip_chat_path(@trip, @chat),
                  alert: "Message cannot be blank."
      return
    end

    @chat.with_instructions(system_prompt)

    @chat.ask(content)

    redirect_to trip_chat_path(@trip, @chat)
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end

  def set_chat
    @chat = @trip.chats.find(params[:chat_id])
  end

  def system_prompt
    <<~PROMPT
      Persona:
      You are TripGen AI, a helpful and practical travel planning assistant.

      Context:
      You are helping the user plan this trip:
      Trip name: #{@trip.title}
      Description: #{@trip.description}
      Start date: #{@trip.start_date}
      End date: #{@trip.end_date}
      Budget: €#{@trip.budget}
      Travel style: #{@trip.travel_style}
      Travelling with: #{@trip.traveling_with}

      Task:
      Help the user plan their trip based on the trip context above.
      Give realistic recommendations that fit their budget, dates and travel style.

      Format:
      Be concise, practical and easy to understand.
    PROMPT
  end
end
