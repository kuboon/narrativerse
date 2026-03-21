class ChatsController < ApplicationController
  def self.parent_class = Plot
  def show
    @chat = current_user.chat
    @plot_id = context_plot_id
    @scene_id = context_scene_id
    unless @chat
      @chat = current_user.chats.create!
      ChatResponseJob.perform_later(@chat.id, content: nil, plot_id: @plot_id, scene_id: @scene_id)
    end

    render layout: false
  end

  private

  def context_plot_id
    params[:plot_id].presence
  end

  def context_scene_id
    params[:scene_id].presence
  end
end
