import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggler"]

  connect() {
    this.handleScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  onScroll() {
    if (window.scrollY > 10) {
      this.element.classList.add("navbar-scrolled")
    } else {
      this.element.classList.remove("navbar-scrolled")
    }
  }
}
