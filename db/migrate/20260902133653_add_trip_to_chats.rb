class AddTripToChats < ActiveRecord::Migration[8.1]
  def change
    add_reference :chats, :trip, null: true, foreign_key: true
  end
end
