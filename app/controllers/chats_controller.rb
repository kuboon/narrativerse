class ChatsController < ApplicationController
  before_action :require_login

  def show
    @chat = current_user.chat || current_user.chats.create!

    render layout: false
  end
end
