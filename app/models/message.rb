class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments
  broadcasts_to :chat
end
