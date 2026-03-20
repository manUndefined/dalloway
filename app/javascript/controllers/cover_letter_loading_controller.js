import { Controller } from "@hotwired/stimulus"

const STEPS = [
  "Analyse du CV",
  "Récupération des infos du profil",
  "Analyse de l'offre d'emploi",
  "Ajout des précisions",
  "Rédaction de la lettre de motivation"
]

export default class extends Controller {
  connect() {
    this.index = 0
    this.render()
    this.interval = setInterval(() => {
      if (this.index < STEPS.length - 1) {
        this.index++
        this.render()
      }
    }, 2800)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  render() {
    this.element.innerHTML = `
      <ul class="cl-steps">
        ${STEPS.map((label, i) => {
          let state
          if (i < this.index) state = "done"
          else if (i === this.index) state = "active"
          else state = "pending"

          const icon = state === "done"
            ? `<svg viewBox="0 0 16 16" fill="none"><polyline points="3,8 6.5,12 13,4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`
            : state === "active"
            ? `<span class="cl-spinner"></span>`
            : ``

          return `<li class="cl-step cl-step--${state}">
            <span class="cl-step-icon">${icon}</span>
            <span class="cl-step-label">${label}</span>
          </li>`
        }).join("")}
      </ul>
    `
  }
}
