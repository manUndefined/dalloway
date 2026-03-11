import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["progress"]

  connect() {
    // Slide in
    requestAnimationFrame(() => {
      this.element.classList.add("flash-visible")
    })

    // Auto dismiss after 4s
    this.timeout = setTimeout(() => this.dismiss(), 4000)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    if (this.dismissing) return
    this.dismissing = true
    this.element.classList.add("flash-exit")
    setTimeout(() => this.element.remove(), 400)
  }
}
