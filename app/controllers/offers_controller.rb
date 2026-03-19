class OffersController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[scrape show]
  skip_before_action :verify_authenticity_token, only: [:scrape]

  def create
    @offer = Offer.new(offer_params)
    if @offer.save
      if params[:commit] == "Lancer la session"
        chat = Chat.create!(title: "Dalloway", user: current_user, offer: @offer)
        chat.messages.create!(role: "assistant", content: opening_message(@offer, current_user))
        redirect_to chat_path(chat), notice: "Session d'entraînement créée."
      else
        redirect_to root_path, notice: "Offre ajoutée avec succès"
      end
    else
      redirect_to root_path, alert: "Erreur : #{@offer.errors.full_messages.join(', ')}"
    end
  end

  def import
    existing = Offer.find_by(url: params[:url])
    if existing
      # Re-scrape description if missing or too short (og:description fallback)
      if existing.description.blank? || existing.description.length < 100
        data = OfferScraper.call(params[:url])
        existing.update(description: data[:description]) if data[:description].present? && data[:description].length > (existing.description&.length || 0)
      end
      redirect_to offer_path(existing)
      return
    end

    data = OfferScraper.call(params[:url])
    offer = Offer.new(
      url: params[:url],
      title: params[:title].presence || data[:title] || "Offre",
      description: data[:description].presence || params[:title] || "Description non disponible",
      city: params[:city].presence || data[:city],
      domain: params[:domain].presence || data[:domain],
      salary: sanitize_salary(data[:salary]) || parse_salary(params[:salary]),
      job_type: params[:job_type].presence || data[:job_type],
      experience_level: data[:experience_level],
      source: "hellowork"
    )

    if offer.save
      redirect_to offer_path(offer)
    else
      redirect_to root_path, alert: "Impossible d'importer cette offre"
    end
  end

  def scrape
    url = params[:url]
    data = OfferScraper.call(url)
    # Ajouter le domain deviné depuis le titre si absent
    if data[:domain].blank? && data[:title].present?
      data[:domain] = guess_domain(data[:title])
    end
    render json: data
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def index
    @offers = Offer.joins(:chats).where(chats: { user_id: current_user.id }).distinct.order(created_at: :desc)
  end

  def show
    @offer = Offer.find(params[:id])
    @cover_letter = CoverLetter.new
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Cette offre n'existe plus"
  end

  def destroy
    @offer = Offer.find(params[:id])
    @offer.destroy
    redirect_to root_path, notice: "L'offre a été supprimée"
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
    params.require(:offer).permit(:url, :title, :description, :city, :domain, :salary, :job_type, :experience_level)
  end

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

  def sanitize_salary(value)
    return nil if value.nil?
    num = value.to_i
    num > 0 && num <= 200_000 ? num : nil
  end

  def parse_salary(salary_str)
    return nil if salary_str.blank?
    numbers = salary_str.scan(/\d[\d\s]*/).map { |n| n.gsub(/\s/, "").to_i }
    return nil if numbers.empty?
    numbers.max <= 200_000 ? numbers.first : nil
  end

  def guess_domain(title)
    t = title.downcase
    return "Développement Web" if t.match?(/ruby|rails|web|frontend|backend|fullstack|react|angular|vue|django|node|php|laravel/)
    return "Data / IA" if t.match?(/data|machine learning|ia\b|ai\b|scientist|analyst|python/)
    return "DevOps / Cloud" if t.match?(/devops|cloud|aws|azure|sre|infra|kubernetes|docker/)
    return "Mobile" if t.match?(/mobile|ios|android|flutter|react native|swift|kotlin/)
    return "Cybersécurité" if t.match?(/security|sécurité|cyber|pentest/)
    nil
  end
end
