class AddTravelingWithToTrips < ActiveRecord::Migration[8.1]
  def change
    add_column :trips, :traveling_with, :string
  end
end
