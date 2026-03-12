class HelloworkScraper
  require "open-uri"
  require "nokogiri"

  BASE_URL = "https://www.hellowork.com"
  SEARCH_URL = "#{BASE_URL}/fr-fr/emploi/recherche.html"

  def self.call(keyword: nil, city: nil, limit: 12)
    params = {}
    params[:k] = keyword if keyword.present?
    params[:l] = city if city.present?

    url = "#{SEARCH_URL}?#{URI.encode_www_form(params)}"
    fetch_offers(url, limit)
  rescue StandardError => e
    Rails.logger.error("[HelloworkScraper] #{e.message}")
    []
  end

  class << self
    private

    def fetch_offers(url, limit)
      html = URI.parse(url).open(
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept-Language" => "fr-FR,fr;q=0.9",
        read_timeout: 10
      ).read

      doc = Nokogiri::HTML(html)
      parse_offers(doc, limit)
    end

    def parse_offers(doc, limit)
      offers = []

      doc.css("[data-cy=serpCard]").each do |card|
        break if offers.size >= limit

        offer = build_offer(card)
        offers << offer if offer
      end

      offers
    end

    def build_offer(card)
      title_link = card.at_css("[data-cy=offerTitle]")
      return nil unless title_link

      href = title_link["href"]
      return nil unless href&.match?(%r{/fr-fr/emplois/\d+\.html})

      # Title is in the p tag inside the link (not h3 which is empty)
      title_p = title_link.at_css("p.tw-typo-l, p[class*='tw-typo-l']")
      title = title_p&.text&.strip
      title ||= title_link["title"]&.split(" - ")&.first&.strip
      return nil if title.blank?

      # Company is the second p inside the link
      company_p = title_link.css("p")[1]
      company = company_p&.text&.strip

      # Location and contract from data-cy attributes
      location = card.at_css("[data-cy=localisationCard]")&.text&.strip
      contract = card.at_css("[data-cy=contractCard]")&.text&.strip

      # Extract salary from card text
      card_text = card.text
      salary = extract_salary(card_text)
      remote = extract_remote(card_text)
      posted_at = extract_posted_at(card_text)

      full_url = href.start_with?("http") ? href : "#{BASE_URL}#{href}"

      {
        title: clean_title(title),
        url: full_url,
        company: company.presence,
        city: location.presence,
        job_type: contract.presence,
        salary: salary,
        remote: remote,
        posted_at: posted_at,
        domain: guess_domain(title)
      }.compact_blank
    end

    def clean_title(title)
      title.gsub(/\s*[HFhf]\/[HFhf]\s*$/, "").strip
    end

    def extract_salary(text)
      # Normalize all Unicode spaces (narrow no-break space U+202F, etc.) to regular spaces
      normalized = text.gsub(/[\u00A0\u202F\u2007\u2009]/, " ")

      if (m = normalized.match(/(\d[\d\s]+)\s*[-–]\s*(\d[\d\s]+)\s*€\s*\/\s*an/))
        min = m[1].gsub(/\s/, "").to_i
        max = m[2].gsub(/\s/, "").to_i
        "#{format_salary(min)} - #{format_salary(max)} € / an"
      elsif (m = normalized.match(/(\d[\d\s]+)\s*€\s*\/\s*an/))
        num = m[1].gsub(/\s/, "").to_i
        "#{format_salary(num)} € / an"
      end
    end

    def format_salary(num)
      num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1 ').reverse
    end

    def extract_remote(text)
      if text.match?(/télétravail complet/i)
        "Télétravail complet"
      elsif text.match?(/télétravail partiel/i)
        "Télétravail partiel"
      elsif text.match?(/télétravail occasionnel/i)
        "Télétravail occasionnel"
      end
    end

    def extract_posted_at(text)
      if (m = text.match(/il y a (\d+)\s*(jour|heure|minute|semaine|mois)/i))
        "il y a #{m[1]} #{m[2]}#{m[1].to_i > 1 ? 's' : ''}"
      elsif text.match?(/aujourd.?hui/i)
        "Aujourd'hui"
      end
    end

    def guess_domain(title)
      t = title.downcase
      return "Développement Web" if t.match?(/ruby|rails|web|frontend|backend|fullstack|react|angular|vue|django|node|php|laravel|java(?!script)|\.net/)
      return "Data / IA" if t.match?(/data|machine learning|ia\b|ai\b|scientist|analyst|python/)
      return "DevOps / Cloud" if t.match?(/devops|cloud|aws|azure|sre|infra|kubernetes|docker/)
      return "Mobile" if t.match?(/mobile|ios|android|flutter|react native|swift|kotlin/)
      return "Cybersécurité" if t.match?(/security|sécurité|cyber|pentest/)
      return "Design" if t.match?(/design|ux|ui|figma/)
      return "Développement" if t.match?(/développeur|developer|ingénieur logiciel|software engineer|informatique/)
      nil
    end
  end
end
