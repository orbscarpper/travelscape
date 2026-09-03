class Chat < ApplicationRecord
  acts_as_chat
  belongs_to :trip

  skip_callback :save, :before, :resolve_model_from_strings
end
