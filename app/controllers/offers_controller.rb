class OffersController < ApplicationController
  def index
    @offers = Offer.all

  end

  def show
    @offer = Offer.find(params[:id])
  end

  def generate_letter
  @offer = Offer.find(params[:id])

  name = params[:name]
  skills = params[:skills]
  experience = params[:experience]

  @letter = "
  Objet : Candidature pour le poste #{@offer.title}

  Madame, Monsieur,

  Je me permets de vous adresser ma candidature pour le poste de #{@offer.title}.

  Développeur passionné, je possède des compétences en #{skills}. 
  #{experience}

  Votre offre a particulièrement retenu mon attention et je serais très motivé à rejoindre votre équipe.

  Je reste à votre disposition pour un entretien.

  Cordialement,

  #{name}
  "

  render :show
end
end
