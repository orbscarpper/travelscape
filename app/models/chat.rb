class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :trip
end
