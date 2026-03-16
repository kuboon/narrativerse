class ChatsController < ApplicationController
  def self.parent_class = Plot

  def create
    return unless prompt.present?

    # Find or create a chat for the current user
    @chat = current_user.chats.first
    unless @chat
      # Initialize with a known basic model. If the gem's default validations require a valid resolved model string for acts_as_chat:
      @chat = current_user.chats.create!
    end

    ChatResponseJob.perform_later(@chat.id, prompt)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("messages", partial: "messages/message", locals: { message: @chat.messages.build(role: "user", content: prompt) })
      end
      format.html { redirect_to chat_path, notice: "Chat was successfully created." }
    end
  end

  def show
    @chat = current_user.chat
    unless @chat
      @chat = current_user.chats.create!
    end
    @chat.messages.create(role: "user")

    @plot_id = context_plot_id
    @scene_id = context_scene_id
    @message = @chat.messages.build

    render layout: false
  end

  private

  def prompt
    params.dig(:chat, :prompt)
  end

  def context_plot_id
    params[:plot_id].presence
  end

  def context_scene_id
    params[:scene_id].presence
  end
end
