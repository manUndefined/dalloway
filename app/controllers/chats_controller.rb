class ChatsController < ApplicationController
  def index
    @chats = current_user.chats.includes(:offer, :messages).order(created_at: :desc)
  end

  def show
    @chat = current_user.chats.includes(:messages, :offer).find(params[:id])
    @message = Message.new
  end

  def create
    @offer = Offer.find(params[:offer_id])

    @chat = Chat.new(
      title: "Dalloway",
      user: current_user,
      offer: @offer
    )

    if @chat.save
      @chat.messages.create!(
        role: "assistant",
        content: opening_message(@offer, current_user)
      )

      redirect_to chat_path(@chat), notice: "Session d'entraînement créée."
    else
      redirect_to offer_path(@offer), alert: "Impossible de créer la session."
    end
  end

  private

  def opening_message(offer, user)
    <<~TEXT
      Bonjour #{user.first_name.presence || 'et bienvenue'} 👋

      Je vais vous entraîner pour votre entretien sur le poste "#{offer.title}".

      Mon rôle :
      - vous poser des questions comme un recruteur
      - adapter les questions à l'offre visée
      - tenir compte de votre profil
      - vous aider à améliorer vos réponses

      Pour commencer, présentez-vous en 4 à 6 phrases comme si vous étiez en entretien.
    TEXT
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    @chat.destroy
    redirect_to chats_path, notice: "Entretien supprimé"
  end
end
