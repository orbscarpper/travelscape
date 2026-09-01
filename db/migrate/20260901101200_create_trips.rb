class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :trips do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.date :start_date
      t.date :end_date
      t.decimal :budget
      t.string :travel_style

      t.timestamps
    end
  end
end
