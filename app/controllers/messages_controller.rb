class MessagesController < ApplicationController
  before_action :require_login
  before_action :set_chat

  def create
    return unless content.present?

    @plot_id = context_plot_id
    @scene_id = context_scene_id

    ChatResponseJob.perform_later(@chat.id, content, @plot_id, @scene_id)

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

  def context_plot_id
    params.dig(:message, :plot_id).presence
  end

  def context_scene_id
    params.dig(:message, :scene_id).presence
  end
end
