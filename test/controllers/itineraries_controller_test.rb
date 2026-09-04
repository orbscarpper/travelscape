require "test_helper"

class ItinerariesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "owner@example.com", password: "password123")
    @trip = @user.trips.create!(
      title: "Paris Weekend",
      start_date: Date.new(2026, 9, 10),
      end_date: Date.new(2026, 9, 12),
      budget: 500
    )
    sign_in @user
  end

  def add_itinerary
    day = @trip.itinerary_days.create!(date: @trip.start_date, day_number: 1, title: "Arrival")
    day.activities.create!(
      user: @user,
      start_time: "09:00",
      end_time: "10:00",
      location: "Louvre",
      estimated_cost: 10
    )
    day
  end

  test "the itinerary page warns before deleting the trip" do
    add_itinerary

    get trip_itinerary_path(@trip)

    assert_response :success
    assert_select "button[data-bs-target='#deleteTripModal']", text: /Delete trip/
    assert_select "#deleteTripModal", text: /permanently remove/
    assert_select "#deleteTripModal form[action='#{trip_path(@trip)}']"
    assert_select "#deleteTripModal input[name='_method'][value='delete']"
  end

  test "the itinerary is no longer reachable once its trip is deleted" do
    add_itinerary
    path = trip_itinerary_path(@trip)

    delete trip_path(@trip)

    get path
    assert_response :not_found
  end

  test "does not render an itinerary page for a trip without an itinerary" do
    get trip_itinerary_path(@trip)
    assert_redirected_to trip_path(@trip)

    get edit_trip_itinerary_path(@trip)
    assert_redirected_to trip_path(@trip)

    follow_redirect!
    assert_select ".days-list", false
    assert_no_match(/YOUR TRAVEL PLAN/, response.body)
  end

  test "does not expose another user's itinerary" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    add_itinerary
    sign_in other_user

    get trip_itinerary_path(@trip)

    assert_response :not_found
  end
end
