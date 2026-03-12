class ChatsController < ApplicationController
  def index
    @chats = current_user.chats.includes(:offer, :messages).order(created_at: :desc)
  end

  def show
    @chat = current_user.chats.includes(:messages, :offer).find(params[:id])
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    @chat.destroy
    redirect_to chats_path, notice: "Entretien supprimé"
  end
end
