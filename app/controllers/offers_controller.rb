class OffersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:scrape]
  skip_before_action :verify_authenticity_token, only: [:scrape]
  
  def create
    @offer = Offer.new(offer_params)
    if @offer.save
      redirect_to root_path, notice: "Offre ajoutée avec succès"
    else
      redirect_to root_path, alert: "Erreur : #{@offer.errors.full_messages.join(', ')}"
    end
  end

  def scrape
    url = params[:url]
    data = OfferScraper.call(url)
    render json: data
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def index
    @offers = Offer.all
  end

  def show
    @offer = Offer.find(params[:id])
    @cover_letter = CoverLetter.new
  end

  def apply
  @offer = Offer.find(params[:id])
  
  # Logique métier ici (ex: envoyer un email au recruteur ou créer un objet 'Application')
  # Application.create(user: current_user, offer: @offer)

  flash[:notice] = "Votre candidature pour le poste de #{@offer.title} a bien été envoyée !"
  redirect_to offer_path(@offer)
end

  private

  def offer_params
    params.require(:offer).permit(:url, :title, :description, :city, :domain, :salary)
  end
end
