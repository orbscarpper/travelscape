class CreateItineraryDays < ActiveRecord::Migration[8.1]
  def change
    create_table :itinerary_days do |t|
      t.references :trip, null: false, foreign_key: true
      t.date :date
      t.integer :day_number
      t.string :title

      t.timestamps
    end
  end
end
