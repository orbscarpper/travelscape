require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  test "creates a user message" do
    user = User.create!(
  email: "test@example.com",
  password: "password123"
)

sign_in user

    trip = user.trips.create!(
      title: "Paris Weekend",
      start_date: Date.new(2026, 9, 10),
      end_date: Date.new(2026, 9, 12),
      budget: 500
    )

    chat = trip.chats.create!

    assert_difference("Message.count", 2) do
  post trip_chat_messages_path(trip, chat),
       params: { content: "What should I visit in Paris?" }

end

   message = chat.messages.first

    assert_equal "user", message.role
    assert_equal "What should I visit in Paris?", message.content
  end
end
