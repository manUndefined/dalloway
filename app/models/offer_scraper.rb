class OfferScraper
  require "open-uri"
  require "nokogiri"
  require "cgi"
  require "json"

  def self.call(url)
    return {} if url.blank?

    result = {}

    # Try URL-based extraction first (works even when scraping is blocked)
    result.merge!(extract_from_url(url))

    # Then try HTML scraping to enrich/override
    begin
      html = URI.parse(url).open(
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        read_timeout: 8
      ).read
      doc = Nokogiri::HTML(html)

      # Skip if anti-bot page
      page_title = doc.title&.strip || ""
      unless page_title.match?(/just a moment|checking your browser|captcha|access denied/i)
        html_data = extract_from_html(doc)
        # Only override with HTML data if values are meaningful
        html_data.each { |k, v| result[k] = v if v.present? }
      end
    rescue StandardError
      # URL extraction is our fallback
    end

    result.compact_blank
  end

  class << self
    private

    # ---- URL-based extraction (reliable) ----
    def extract_from_url(url)
      uri = URI.parse(url) rescue nil
      return {} unless uri

      host = uri.host&.downcase || ""
      path = URI.decode_www_form_component(uri.path || "")
      query = uri.query ? URI.decode_www_form(uri.query).to_h : {}

      data = {}

      if host.include?("indeed")
        data.merge!(parse_indeed_url(path, query))
      elsif host.include?("linkedin")
        data.merge!(parse_linkedin_url(path))
      elsif host.include?("welcometothejungle")
        data.merge!(parse_wttj_url(path))
      elsif host.include?("glassdoor")
        data.merge!(parse_glassdoor_url(path))
      else
        data.merge!(parse_generic_url(path, query))
      end

      data[:domain] ||= guess_domain_from_text(data[:title]) if data[:title]
      data
    end

    def parse_indeed_url(path, query)
      data = {}
      # /viewjob?jk=xxx or /jobs?q=developer&l=Paris
      if query["q"].present?
        data[:title] = query["q"].gsub(/[+_-]/, " ").titleize
      end
      if query["l"].present?
        data[:city] = query["l"].gsub(/[+_-]/, " ").titleize
      end
      # /emplois-Developer-Paris path format
      if path.match?(/emplois?[_-]/i)
        parts = path.split(/[_-]/).map(&:strip).reject(&:blank?)
        parts.shift # remove "emplois"
        data[:title] ||= parts.first&.titleize
        data[:city] ||= parts.last&.titleize if parts.size > 1
      end
      data
    end

    def parse_linkedin_url(path)
      data = {}
      # /jobs/view/developer-ruby-paris-12345/
      if (match = path.match(%r{/jobs/view/(.+?)/?$}))
        slug = match[1].gsub(/[-_]\d+$/, "") # remove trailing ID
        parts = slug.split("-")
        data[:title] = parts[0...-1].join(" ").titleize if parts.size > 1
        data[:city] = parts.last.titleize
      end
      data
    end

    def parse_wttj_url(path)
      data = {}
      # /fr/companies/company-name/jobs/job-slug
      if (match = path.match(%r{/companies/(.+?)/jobs/(.+?)/?$}))
        data[:domain] = match[1].gsub(/[-_]/, " ").titleize
        data[:title] = match[2].gsub(/[-_]/, " ").titleize
      end
      data
    end

    def parse_glassdoor_url(path)
      data = {}
      if (match = path.match(%r{/job-listing/(.+?)(?:-\w+)?\.htm}))
        data[:title] = match[1].gsub(/[-_]/, " ").titleize
      end
      data
    end

    def parse_generic_url(path, query)
      data = {}
      # Try to extract title from last meaningful path segment
      segments = path.split("/").reject(&:blank?)
      if segments.any?
        slug = segments.last.gsub(/\.\w+$/, "") # remove extension
        data[:title] = slug.gsub(/[-_]/, " ").titleize if slug.length > 3
      end
      data
    end

    def guess_domain_from_text(text)
      t = text.downcase
      return "Développement Web" if t.match?(/ruby|rails|web|frontend|backend|fullstack|react|angular|vue|django|node|php|laravel/)
      return "Data / IA" if t.match?(/data|machine learning|ia|ai|scientist|analyst|python/)
      return "DevOps / Cloud" if t.match?(/devops|cloud|aws|azure|sre|infra|kubernetes|docker/)
      return "Mobile" if t.match?(/mobile|ios|android|flutter|react native|swift|kotlin/)
      return "Cybersécurité" if t.match?(/security|sécurité|cyber|pentest/)
      return "Design" if t.match?(/design|ux|ui|figma|product design/)
      nil
    end

    # ---- HTML-based extraction (best effort) ----
    def extract_from_html(doc)
      {
        title: extract_title(doc),
        description: extract_description(doc),
        city: extract_city(doc),
        domain: extract_domain(doc),
        salary: extract_salary(doc),
        job_type: extract_job_type(doc),
        experience_level: extract_experience_level(doc)
      }
    end

    def extract_title(doc)
      # HelloWork detail page: data-cy=jobTitle inside h1
      hw_job = doc.at_css("[data-cy=jobTitle]")&.text&.strip
      return hw_job if hw_job.present?

      # HelloWork search card: p inside offerTitle link
      hw_title = doc.at_css("[data-cy=offerTitle] p.tw-typo-l")&.text&.strip
      return hw_title if hw_title.present?

      # Generic: og:title (split on " - " to remove site name)
      og = doc.at_css('meta[property="og:title"]')&.[]("content")
      return og.split(" - ").first.strip if og.present?

      doc.at_css("h1")&.text&.strip ||
        doc.title&.strip
    end

    def extract_description(doc)
      # Priority 1: JSON-LD structured data (most reliable, full description)
      doc.css('script[type="application/ld+json"]').each do |script|
        begin
          data = JSON.parse(script.text)
          if data["@type"] == "JobPosting" && data["description"].present?
            return clean_html_description(data["description"])
          end
        rescue JSON::ParserError
          next
        end
      end

      # Priority 2: generic job description containers
      desc_el = doc.at_css('[class*="job-description"], [id*="jobDescription"], [id*="job-description"]')
      return clean_description(desc_el) if desc_el

      # Priority 3: og:description fallback
      og = doc.at_css('meta[property="og:description"]')&.[]("content")
      return og.strip if og.present? && og.length > 20

      meta = doc.at_css('meta[name="description"]')&.[]("content")
      return meta.strip if meta.present? && meta.length > 20

      nil
    end

    def clean_html_description(html_string)
      html_string
        .gsub(/<br\s*\/?>/, "\n")
        .gsub(/<\/?(p|div|li|h[1-6])[^>]*>/, "\n")
        .gsub(/<[^>]+>/, "")
        .then { |t| CGI.unescapeHTML(t) }
        .gsub(/[ \t]+/, " ")
        .gsub(/\n{3,}/, "\n\n")
        .strip
        .truncate(3000)
        .presence
    end

    def clean_description(element)
      clean_html_description(element.inner_html)
    end

    def extract_city(doc)
      # HelloWork specific
      hw_loc = doc.at_css("[data-cy=localisationCard], [data-cy=localisation]")&.text&.strip
      return hw_loc if hw_loc.present?

      selectors = [
        '[class*="jobLocation"]', '[class*="job-location"]',
        '[data-testid*="location"]', '[class*="location"]', '[class*="Location"]',
        '[class*="lieu"]', '[itemprop="jobLocation"]',
        '[itemprop="addressLocality"]'
      ]
      selectors.each do |sel|
        el = doc.at_css(sel)
        text = el&.text&.strip
        return text if text.present? && text.length < 100
      end
      nil
    end

    def extract_domain(doc)
      selectors = [
        '[class*="industry"]', '[class*="Industry"]',
        '[class*="sector"]', '[class*="Sector"]',
        '[itemprop="industry"]'
      ]
      selectors.each do |sel|
        el = doc.at_css(sel)
        text = el&.text&.strip
        return text if text.present? && text.length < 100
      end
      nil
    end

    def extract_job_type(doc)
      # HelloWork specific
      hw_contract = doc.at_css("[data-cy=contractCard], [data-cy=contract]")&.text&.strip
      return hw_contract if hw_contract.present?

      text = doc.text
      return "CDI" if text.match?(/\bCDI\b/)
      return "CDD" if text.match?(/\bCDD\b/)
      return "Freelance" if text.match?(/\bFreelance\b/i)
      return "Stage" if text.match?(/\bStage\b/i)
      return "Alternance" if text.match?(/\bAlternance\b/i)
      nil
    end

    def extract_experience_level(doc)
      text = doc.text.downcase
      return "Junior" if text.match?(/junior|débutant|0[\s-]+[23]\s*ans?|1[\s-]+[23]\s*ans?/)
      return "Senior" if text.match?(/senior|expérimenté|[5-9]\+?\s*ans?|10\+?\s*ans?/)
      return "Intermédiaire" if text.match?(/intermédiaire|confirmé|[3-5]\s*ans?/)
      nil
    end

    def extract_salary(doc)
      # Try structured elements
      selectors = [
        '[class*="salary"]', '[class*="Salary"]',
        '[id*="salary"]', '[class*="compensation"]', '[class*="Compensation"]',
        '[class*="remuneration"]', '[class*="Remuneration"]', '[itemprop="baseSalary"]'
      ]
      selectors.each do |sel|
        el = doc.at_css(sel)
        if el
          num = extract_number(el.text)
          return num if num
        end
      end

      # Try regex on full text (normalize Unicode spaces)
      text = doc.text.gsub(/[\u00A0\u202F\u2007\u2009]/, " ")
      # Range: "38 000 - 43 000 €" or "38 000 - 43 000 € / an"
      if (m = text.match(/(\d[\d\s]+)\s*[-–]\s*(\d[\d\s]+)\s*€/))
        avg = (m[1].gsub(/\s/, "").to_i + m[2].gsub(/\s/, "").to_i) / 2
        return avg if avg > 10_000
      end
      if (m = text.match(/(\d{2,3})\s*000\s*[€$]/))
        return m[1].to_i * 1000
      end
      if (m = text.match(/(\d{2,3})\s*[kK]\s*[€$]/))
        return m[1].to_i * 1000
      end
      nil
    end

    def extract_number(text)
      if (m = text.match(/(\d[\d\s,.]*)\s*[€$kK]/))
        num = m[1].gsub(/[\s,.]/, "").to_i
        num = num * 1000 if num < 1000 && text.match?(/[kK]/)
        return num if num > 10_000
      end
      nil
    end
  end
end
