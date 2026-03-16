class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    @offers = filtered_offers
    @hellowork_offers = fetch_hellowork_offers
    @stats = {
      offers: Offer.count,
      interviews: Chat.count,
      users: User.count
    }
  end

  private

  def filtered_offers
    offers = Offer.where(source: "manual").order(created_at: :desc)

    if user_signed_in? && current_user
      offers = offers.where(job_type: current_user.preferred_job_type) if current_user.preferred_job_type.present?
      if current_user.preferred_experience_level.present?
        offers = offers.where(experience_level: current_user.preferred_experience_level)
      end
      offers = offers.where(domain: current_user.preferred_sector) if current_user.preferred_sector.present?
      offers = offers.where(city: current_user.preferred_city) if current_user.preferred_city.present?
      offers = offers.where("salary >= ?", current_user.preferred_salary) if current_user.preferred_salary.present?
    end

    offers
  end

  def fetch_hellowork_offers
    if params[:keyword].present?
      keyword = params[:keyword]
    elsif user_signed_in? && current_user.preferred_sector.present?
      keyword = current_user.preferred_sector
    else
      keyword = nil
    end

    city = if params[:city].present?
             params[:city]
           elsif user_signed_in?
             current_user.preferred_city
           end

    contract = params[:contract].presence
    @search_keyword = keyword
    @search_city = city
    @search_contract = contract

    search_keyword = [keyword, contract].compact.join(" ").presence

    if search_keyword.present?
      cache_key = "hellowork_offers/#{search_keyword}/#{city}"
      Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        HelloworkScraper.call(keyword: search_keyword, city: city, limit: 8)
      end
    else
      keywords = ["développeur web", "data analyst", "devops", "chef de projet IT", "développeur mobile", "UX designer"]
      offers = []
      keywords.each do |kw|
        cache_key = "hellowork_offers/#{kw}/#{city}"
        results = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
          HelloworkScraper.call(keyword: kw, city: city, limit: 2)
        end
        offers.concat(results)
      end
      offers.shuffle.first(8)
    end
  end
end
