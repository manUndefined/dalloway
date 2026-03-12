import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = ["messages", "form", "submit", "typing"]

  connect() {
    this.scrollToBottom()
  }

  submitting() {
    if (this.hasTypingTarget) {
      this.typingTarget.classList.remove("d-none")
    }

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.value = "Envoi..."
    }

    this.scrollToBottom()
  }

  submitted() {
    if (this.hasTypingTarget) {
      this.typingTarget.classList.add("d-none")
    }

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.value = "Envoyer"
    }

    setTimeout(() => {
      this.scrollToBottom()
    }, 100)
  }

  scrollToBottom() {
    window.scrollTo({
      top: document.body.scrollHeight,
      behavior: "smooth"
    })
  }
}