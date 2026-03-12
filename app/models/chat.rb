class Chat < ApplicationRecord
  belongs_to :user
  acts_as_chat
end
