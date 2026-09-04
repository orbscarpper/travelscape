class AddDestinationToTrips < ActiveRecord::Migration[8.1]
  def change
    add_column :trips, :destination, :string
  end
end
