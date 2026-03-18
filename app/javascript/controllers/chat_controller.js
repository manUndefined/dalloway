import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = ["messages", "form", "submit"]

  connect() {
    setTimeout(() => {
      this.scrollToBottom()
    }, 50)

    const textarea = this.formTarget.querySelector("textarea")
    if (textarea) {
      textarea.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && !e.shiftKey) {
          e.preventDefault()
          if (textarea.value.trim().length > 0) {
            this.formTarget.requestSubmit()
          }
        }
      })
    }
  }

  submitting() {
    const textarea = this.formTarget.querySelector("textarea")
    if (!textarea) return

    const content = textarea.value.trim()
    if (content.length === 0) return

    this.appendOptimisticUserMessage(content)
    this.showTypingIndicator()

    this.formTarget.reset()

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.value = "Envoi..."
    }

    this.scrollToBottom()
  }

  submitted() {
    this.removeTypingIndicator()

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.value = "Envoyer"
    }

    setTimeout(() => {
      this.scrollToBottom()
    }, 100)
  }

  appendOptimisticUserMessage(content) {
    const firstLetter = this.userInitial()
    const html = `
      <div class="chat-bubble chat-bubble-user optimistic-user-message">
        <div class="chat-bubble-content">
          <div class="chat-bubble-role">Vous</div>
          <div class="chat-bubble-text">
            <p>${this.escapeHtml(content)}</p>
          </div>
        </div>

        <div class="chat-bubble-avatar">
          <span>${firstLetter}</span>
        </div>
      </div>
    `

    this.messagesTarget.insertAdjacentHTML("beforeend", html)
  }

  showTypingIndicator() {
    this.removeTypingIndicator()

    const html = `
      <div class="chat-bubble chat-bubble-assistant" id="typing-indicator">
        <div class="chat-bubble-avatar">
          <i class="fa-solid fa-robot"></i>
        </div>

        <div class="chat-bubble-content">
          <div class="chat-bubble-role">Dalloway IA</div>
          <div class="chat-bubble-text">
            <p>Dalloway écrit...</p>
          </div>
        </div>
      </div>
    `

    this.messagesTarget.insertAdjacentHTML("beforeend", html)
  }

  removeTypingIndicator() {
    const indicator = document.getElementById("typing-indicator")
    if (indicator) indicator.remove()
  }

  userInitial() {
    const avatar = document.querySelector(".navbar .avatar, .navbar-avatar")
    return "U"
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML.replace(/\n/g, "<br>")
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}