require "application_system_test_case"

class DeleteTripTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  teardown { Warden.test_reset! }

  def setup_trip(email, title: "Paris Weekend")
    user = User.create!(email: email, password: "password123")
    trip = user.trips.create!(title: title, start_date: Date.new(2026, 9, 10),
                              end_date: Date.new(2026, 9, 12), budget: 500)
    day = trip.itinerary_days.create!(date: trip.start_date, day_number: 1, title: "Arrival")
    day.activities.create!(user: user, start_time: "09:00", end_time: "10:00",
                           location: "Louvre", estimated_cost: 10)
    login_as(user, scope: :user)
    [user, trip]
  end

  test "deleting from the itinerary page removes the trip entirely" do
    _user, trip = setup_trip("s1@example.com")

    visit trip_itinerary_path(trip)
    click_button "Delete trip"
    assert_text "Delete this trip?"
    click_button "Yes, delete it"

    assert_text "Trip deleted successfully!"
    assert_no_text "Paris Weekend"
    assert_no_text "Louvre"
    assert_equal 0, Trip.count
    assert_equal 0, ItineraryDay.count
    assert_equal 0, Activity.count
    assert_current_path trips_path
  end

  test "deleting from the trip page removes it from My Trips" do
    _user, trip = setup_trip("s2@example.com")

    visit trip_path(trip)
    click_button "Delete trip"
    click_button "Yes, delete it"

    assert_current_path trips_path
    assert_no_text "Paris Weekend"
    assert_equal 0, Trip.count
  end

  test "deleting from My Trips removes only the chosen trip" do
    user, keeper = setup_trip("s3@example.com", title: "Keep Me")
    doomed = user.trips.create!(title: "Delete Me", start_date: Date.new(2026, 11, 1),
                                end_date: Date.new(2026, 11, 2), budget: 200)

    visit trips_path
    assert_text "Keep Me"
    assert_text "Delete Me"

    find("button[data-bs-target='#deleteTripModal-#{doomed.id}']").click
    within "#deleteTripModal-#{doomed.id}" do
      click_button "Yes, delete it"
    end

    assert_text "Trip deleted successfully!"
    assert_no_text "Delete Me"
    assert_text "Keep Me"
    assert_equal [keeper.id], Trip.pluck(:id)
  end

  test "a trip with no itinerary can still be deleted" do
    user = User.create!(email: "s4@example.com", password: "password123")
    user.trips.create!(title: "Bare Trip", start_date: Date.new(2026, 12, 1),
                       end_date: Date.new(2026, 12, 2), budget: 100)
    login_as(user, scope: :user)

    visit trips_path
    click_button "Delete trip"
    click_button "Yes, delete it"

    assert_no_text "Bare Trip"
    assert_equal 0, Trip.count
  end
end
