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

  @chat.messages.create!(
    role: "user",
    content: content
  )

  @chat.messages.create!(
    role: "assistant",
    content: "For your first day in Paris, I recommend visiting the Eiffel Tower, walking around the Latin Quarter, and having dinner in Le Marais."
  )

  redirect_to trip_chat_path(@trip, @chat)
end

  private

  def set_trip
    @trip = current_user.trips.find(params[:trip_id])
  end

  def set_chat
    @chat = @trip.chats.find(params[:chat_id])
  end
end
