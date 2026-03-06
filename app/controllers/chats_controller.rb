class ChatsController < ApplicationController
  INITIAL_PLOT_CHOICES_PROMPT = "何から始めましょうか？".freeze
  INITIAL_PLOT_CHOICES = [
    "登場人物や場面を先に決める",
    "あらすじを先に決める",
    "何も決まっていないので、提案してほしい"
  ].freeze

  before_action :require_login
  before_action :set_chat, only: [ :show ]

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
    unless @chat
      @chat = current_user.chats.create!
    end

    seed_initial_plot_choices_if_needed

    @plot_id = context_plot_id
    @scene_id = context_scene_id
    @message = @chat.messages.build
    render layout: false
  end

  private

  def set_chat
    @chat = current_user.chats.first
  end

  def prompt
    params.dig(:chat, :prompt)
  end

  def context_plot_id
    params[:plot_id].presence
  end

  def context_scene_id
    params[:scene_id].presence
  end

  def seed_initial_plot_choices_if_needed
    return unless auto_start_requested?

    plot = current_user.plots.find_by(id: context_plot_id)
    return unless plot&.title.blank?

    welcomed_plot_ids = Array(session[:chatbot_welcomed_plot_ids]).map(&:to_s)
    plot_id = plot.id.to_s
    return if welcomed_plot_ids.include?(plot_id)

    @chat.messages.create!(
      role: "assistant",
      content: JSON.generate(
        type: "choices",
        prompt: INITIAL_PLOT_CHOICES_PROMPT,
        choices: INITIAL_PLOT_CHOICES
      )
    )

    session[:chatbot_welcomed_plot_ids] = (welcomed_plot_ids << plot_id).last(30)
  end

  def auto_start_requested?
    ActiveModel::Type::Boolean.new.cast(params[:autostart])
  end
end
