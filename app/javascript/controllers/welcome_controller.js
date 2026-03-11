import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["particles", "content"]

  connect() {
    this.createParticles()
    this.animateEntry()

    // Auto-dismiss after 7s
    this.timeout = setTimeout(() => this.dismiss(), 7000)

    // Click to dismiss early
    this.element.addEventListener("click", () => this.dismiss())
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  createParticles() {
    const container = this.particlesTarget
    const colors = ["#0D6EFD", "#1EDD88", "#FFC65A", "#FD1015", "#fff"]
    const shapes = ["circle", "square", "triangle"]

    for (let i = 0; i < 60; i++) {
      const particle = document.createElement("div")
      particle.classList.add("particle")

      const shape = shapes[Math.floor(Math.random() * shapes.length)]
      particle.classList.add(`particle-${shape}`)

      const color = colors[Math.floor(Math.random() * colors.length)]
      particle.style.setProperty("--color", color)
      particle.style.left = `${Math.random() * 100}%`
      particle.style.top = `${Math.random() * 100}%`
      particle.style.animationDelay = `${Math.random() * 0.8}s`
      particle.style.animationDuration = `${1.5 + Math.random() * 2}s`
      particle.style.setProperty("--tx", `${(Math.random() - 0.5) * 400}px`)
      particle.style.setProperty("--ty", `${(Math.random() - 0.5) * 400}px`)
      particle.style.setProperty("--r", `${Math.random() * 720 - 360}deg`)
      particle.style.setProperty("--scale", `${0.5 + Math.random() * 1}`)

      container.appendChild(particle)
    }
  }

  animateEntry() {
    requestAnimationFrame(() => {
      this.element.classList.add("welcome-visible")
    })
  }

  dismiss() {
    if (this.dismissing) return
    this.dismissing = true
    this.element.classList.add("welcome-exit")
    setTimeout(() => this.element.remove(), 600)
  }
}
