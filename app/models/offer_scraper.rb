class OfferScraper
  require "open-uri"
  require "nokogiri"

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
        salary: extract_salary(doc)
      }
    end

    def extract_title(doc)
      doc.at_css('meta[property="og:title"]')&.[]("content") ||
        doc.at_css("h1")&.text&.strip ||
        doc.title&.strip
    end

    def extract_description(doc)
      # Try structured data first
      og = doc.at_css('meta[property="og:description"]')&.[]("content")
      return og if og.present? && og.length > 20

      meta = doc.at_css('meta[name="description"]')&.[]("content")
      return meta if meta.present? && meta.length > 20

      # Try job description containers
      desc_el = doc.at_css('[class*="jobDescription"], [class*="job-description"], [id*="jobDescription"], [class*="description"]')
      return desc_el.text.strip.truncate(500) if desc_el

      doc.css("p").first(5).map { |p| p.text.strip }.reject(&:blank?).join(" ").truncate(500).presence
    end

    def extract_city(doc)
      selectors = [
        '[class*="jobLocation"]', '[class*="job-location"]',
        '[data-testid*="location"]', '[class*="location" i]',
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

    def extract_salary(doc)
      # Try structured elements
      selectors = [
        '[class*="salary" i]', '[class*="Salary"]',
        '[id*="salary" i]', '[class*="compensation" i]',
        '[class*="remuneration" i]', '[itemprop="baseSalary"]'
      ]
      selectors.each do |sel|
        el = doc.at_css(sel)
        if el
          num = extract_number(el.text)
          return num if num
        end
      end

      # Try regex on full text
      text = doc.text
      # Match patterns like "45 000 €", "45K€", "45k", "45000€"
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
