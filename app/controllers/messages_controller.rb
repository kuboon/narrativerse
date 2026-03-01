class MessagesController < ApplicationController
  before_action :require_login
  before_action :set_chat

  def create
    return unless content.present?

    ChatResponseJob.perform_later(@chat.id, content)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path }
    end
  end

  private

  def set_chat
    @chat = current_user.chats.first
  end

  def content
    params[:message][:content]
  end
end
