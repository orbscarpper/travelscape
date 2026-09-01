class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :itinerary_day, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.time :start_time
      t.time :end_time
      t.string :location
      t.decimal :estimated_cost

      t.timestamps
    end
  end
end
