class Chat < ApplicationRecord
  belongs_to :user
  acts_as_chat messages_foreign_key: :chat_id

  after_initialize :assume_model_exists_on_test

  private

  def assume_model_exists_on_test
    return unless Rails.env.test?
    self.provider ||= "stub"
  end
end
