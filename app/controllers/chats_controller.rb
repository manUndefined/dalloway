class ChatsController < ApplicationController
  def index
    @chats = current_user.chats.includes(:offer, :messages).order(created_at: :desc)
  end

  def show
    @chat = current_user.chats.includes(:messages, :offer).find(params[:id])
  end
end
