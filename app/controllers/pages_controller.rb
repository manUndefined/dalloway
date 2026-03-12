class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    @offers = filtered_offers
    @hellowork_offers = fetch_hellowork_offers
  end

  private

  def filtered_offers
    offers = Offer.order(created_at: :desc)

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
    keyword = if user_signed_in? && current_user.preferred_sector.present?
                current_user.preferred_sector
              else
                "développeur web"
              end
    city = user_signed_in? ? current_user.preferred_city : nil

    cache_key = "hellowork_offers/#{keyword}/#{city}"
    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      HelloworkScraper.call(keyword: keyword, city: city, limit: 12)
    end
  end
end
