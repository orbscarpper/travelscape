require "test_helper"

class TripsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "traveler@example.com", password: "password123")
    @trip = @user.trips.create!(
      title: "Paris Weekend",
      start_date: Date.new(2026, 9, 10),
      end_date: Date.new(2026, 9, 12),
      budget: 500
    )
    day = @trip.itinerary_days.create!(date: @trip.start_date, day_number: 1, title: "Arrival")
    day.activities.create!(
      user: @user,
      start_time: "09:00",
      end_time: "10:00",
      location: "Louvre",
      estimated_cost: 10
    )
    sign_in @user
  end

  test "deleting a trip removes the trip, its itinerary and its activities" do
    assert_difference ["Trip.count", "ItineraryDay.count", "Activity.count"], -1 do
      delete trip_path(@trip)
    end

    assert_redirected_to trips_path
    assert_equal "Trip deleted successfully!", flash[:notice]
  end

  test "deleting a trip also removes its chats and messages" do
    chat = Chat.create!(trip: @trip)
    chat.messages.create!(role: "user", content: "Hello")

    assert_difference ["Trip.count", "Chat.count"], -1 do
      assert_difference "Message.count", -1 do
        delete trip_path(@trip)
      end
    end

    assert_redirected_to trips_path
  end

  test "the deleted trip is gone from the trips page" do
    delete trip_path(@trip)
    follow_redirect!

    assert_response :success
    assert_no_match(/Paris Weekend/, response.body)
    assert_select ".alert", text: /Trip deleted successfully/
  end

  test "does not allow a user to delete another user's trip" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    sign_in other_user

    assert_no_difference "Trip.count" do
      delete trip_path(@trip)
    end

    assert_response :not_found
  end

  test "shows a delete control with a warning on the trip page" do
    get trip_path(@trip)

    assert_response :success
    assert_select "button[data-bs-target='#deleteTripModal']", text: /Delete trip/
    assert_select "#deleteTripModal", text: /permanently remove/
    assert_select "#deleteTripModal form[action='#{trip_path(@trip)}']"
    assert_select "#deleteTripModal input[name='_method'][value='delete']"
  end

  test "shows a delete control on the trips page for every trip" do
    without_itinerary = @user.trips.create!(
      title: "Rome someday",
      start_date: Date.new(2026, 10, 1),
      end_date: Date.new(2026, 10, 3),
      budget: 400
    )

    get trips_path

    assert_response :success
    [@trip, without_itinerary].each do |trip|
      assert_select "button[data-bs-target='#deleteTripModal-#{trip.id}']", text: /Delete trip/
      assert_select "#deleteTripModal-#{trip.id} form[action='#{trip_path(trip)}']"
    end
  end

  test "a trip without an itinerary can still be deleted" do
    bare_trip = @user.trips.create!(
      title: "Rome someday",
      start_date: Date.new(2026, 10, 1),
      end_date: Date.new(2026, 10, 3),
      budget: 400
    )

    get trip_path(bare_trip)
    assert_select "button[data-bs-target='#deleteTripModal']", text: /Delete trip/
    assert_select "button.regenerate-button", false

    assert_difference "Trip.count", -1 do
      delete trip_path(bare_trip)
    end

    assert_redirected_to trips_path
  end
end
