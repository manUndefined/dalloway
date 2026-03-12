import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "title", "city", "domain", "salary", "spinner", "jobType", "experienceLevel", "description"]

  connect() {
    this.timeout = null
  }

  paste(event) {
    const pasted = (event.clipboardData || window.clipboardData)?.getData("text")
    if (pasted) {
      setTimeout(() => {
        if (!this.urlTarget.value && pasted) this.urlTarget.value = pasted
        this.autofill()
      }, 200)
    } else {
      setTimeout(() => this.autofill(), 200)
    }
  }

  inputChanged() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.autofill(), 600)
  }

  async autofill() {
    const url = this.urlTarget.value.trim()
    if (!url || !url.startsWith("http")) return

    this.showSpinner()

    try {
      const response = await fetch("/offers/scrape", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: JSON.stringify({ url: url })
      })

      if (response.ok) {
        const data = await response.json()
        this.fillFromData(data)
      } else {
        // Fallback: extraction côté client depuis l'URL
        const data = this.extractFromUrl(url)
        this.fillFromData(data)
      }
    } catch (e) {
      // Fallback client-side
      const data = this.extractFromUrl(url)
      this.fillFromData(data)
    }

    this.hideSpinner()
  }

  fillFromData(data) {
    if (data.title && this.hasTitleTarget) this.fillField(this.titleTarget, data.title)
    if (data.city && this.hasCityTarget) this.fillField(this.cityTarget, data.city)
    if (data.domain && this.hasDomainTarget) this.fillField(this.domainTarget, data.domain)
    if (data.salary && this.hasSalaryTarget) this.fillField(this.salaryTarget, data.salary)
    if (data.job_type && this.hasJobTypeTarget) this.fillSelect(this.jobTypeTarget, data.job_type)
    if (data.experience_level && this.hasExperienceLevelTarget) this.fillSelect(this.experienceLevelTarget, data.experience_level)
    if (data.description && this.hasDescriptionTarget) this.fillField(this.descriptionTarget, data.description)
  }

  extractFromUrl(url) {
    try {
      const parsed = new URL(url)
      const host = parsed.hostname.toLowerCase()
      const path = decodeURIComponent(parsed.pathname)
      const params = Object.fromEntries(parsed.searchParams)

      let data = {}

      if (host.includes("indeed")) {
        data = this.parseIndeed(path, params)
      } else if (host.includes("linkedin")) {
        data = this.parseLinkedin(path)
      } else if (host.includes("welcometothejungle")) {
        data = this.parseWttj(path)
      } else if (host.includes("glassdoor")) {
        data = this.parseGlassdoor(path)
      } else if (host.includes("hellowork") || host.includes("meteojob")) {
        data = this.parseHellowork(path)
      } else {
        data = this.parseGeneric(path)
      }

      if (data.title) {
        data.domain = data.domain || this.guessDomain(data.title)
      }

      return data
    } catch (e) {
      return {}
    }
  }

  parseIndeed(path, params) {
    const data = {}
    if (params.q) data.title = this.cleanSlug(params.q)
    if (params.l) data.city = this.cleanSlug(params.l)
    if (!data.title) {
      const emploiMatch = path.match(/\/emplois?[_-](.+)/i)
      if (emploiMatch) {
        const parts = emploiMatch[1].split(/[-_]/).filter(p => p.length > 1)
        if (parts.length >= 1) data.title = this.cleanSlug(parts.slice(0, -1).join(" ") || parts[0])
        if (parts.length >= 2) data.city = this.cleanSlug(parts[parts.length - 1])
      }
    }
    return data
  }

  parseLinkedin(path) {
    const data = {}
    const match = path.match(/\/jobs\/view\/(.+?)\/?\??/)
    if (match) {
      const slug = match[1].replace(/-\d+$/, "")
      const parts = slug.split("-")
      if (parts.length > 1) {
        const lastPart = parts[parts.length - 1]
        if (lastPart.match(/^\d+$/)) {
          data.title = this.cleanSlug(parts.slice(0, -1).join(" "))
        } else {
          data.title = this.cleanSlug(parts.slice(0, -1).join(" "))
          data.city = this.cleanSlug(lastPart)
        }
      } else {
        data.title = this.cleanSlug(slug)
      }
    }
    return data
  }

  parseWttj(path) {
    const data = {}
    const match = path.match(/\/companies\/(.+?)\/jobs\/(.+?)(?:\/|$)/)
    if (match) {
      data.domain = this.cleanSlug(match[1])
      data.title = this.cleanSlug(match[2])
    }
    return data
  }

  parseGlassdoor(path) {
    const data = {}
    const match = path.match(/\/job-listing\/(.+?)(?:-\w+)?\.htm/)
    if (match) {
      data.title = this.cleanSlug(match[1])
    }
    return data
  }

  parseHellowork(path) {
    const data = {}
    const match = path.match(/\/offre[s-]?emploi\/(.+?)(?:\.html)?$/)
    if (match) {
      const parts = match[1].split("-").filter(p => p.length > 1)
      if (parts.length >= 2) {
        data.title = this.cleanSlug(parts.slice(0, -1).join(" "))
        data.city = this.cleanSlug(parts[parts.length - 1])
      }
    }
    return data
  }

  parseGeneric(path) {
    const data = {}
    const segments = path.split("/").filter(s => s.length > 2)
    if (segments.length > 0) {
      const slug = segments[segments.length - 1].replace(/\.\w+$/, "")
      if (slug.length > 3) data.title = this.cleanSlug(slug)
    }
    return data
  }

  cleanSlug(text) {
    return text
      .replace(/[-_+]/g, " ")
      .replace(/\s+/g, " ")
      .trim()
      .replace(/\b\w/g, c => c.toUpperCase())
  }

  guessDomain(title) {
    const t = title.toLowerCase()
    if (/ruby|rails|web|frontend|backend|fullstack|react|angular|vue|django|node|php|laravel|javascript|typescript/.test(t)) return "Développement Web"
    if (/data|machine learning|ia|ai|scientist|analyst|python|nlp/.test(t)) return "Data / IA"
    if (/devops|cloud|aws|azure|sre|infra|kubernetes|docker|platform/.test(t)) return "DevOps / Cloud"
    if (/mobile|ios|android|flutter|react native|swift|kotlin/.test(t)) return "Mobile"
    if (/security|sécurité|cyber|pentest/.test(t)) return "Cybersécurité"
    if (/design|ux|ui|figma|product design/.test(t)) return "Design"
    if (/product|chef de produit|po\b|product owner|product manager/.test(t)) return "Product"
    if (/commercial|sales|business|account/.test(t)) return "Commercial"
    return null
  }

  fillField(target, value) {
    if (target.value) return // don't overwrite existing values
    target.value = value
    target.classList.add("offer-input-filled")
    setTimeout(() => target.classList.remove("offer-input-filled"), 1000)
  }

  fillSelect(target, value) {
    if (target.value) return // don't overwrite existing values
    // Match option by text content (case-insensitive)
    const options = target.querySelectorAll("option")
    for (const opt of options) {
      if (opt.text.toLowerCase().trim() === value.toLowerCase().trim()) {
        target.value = opt.value
        target.classList.add("offer-input-filled")
        setTimeout(() => target.classList.remove("offer-input-filled"), 1000)
        return
      }
    }
    // Try partial match
    for (const opt of options) {
      if (opt.text.toLowerCase().includes(value.toLowerCase()) || value.toLowerCase().includes(opt.text.toLowerCase())) {
        target.value = opt.value
        target.classList.add("offer-input-filled")
        setTimeout(() => target.classList.remove("offer-input-filled"), 1000)
        return
      }
    }
  }

  showSpinner() {
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.add("visible")
  }

  hideSpinner() {
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.remove("visible")
  }
}
