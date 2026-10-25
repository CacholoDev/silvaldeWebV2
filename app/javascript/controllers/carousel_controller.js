import { Controller } from "@hotwired/stimulus"

// Accessible photo carousel for the landing page.
//
// - Every slide is a real link, so it works without JavaScript.
// - Prev/next buttons are labelled for screen readers and reachable by
//   keyboard.
// - Auto-advance is disabled when the visitor asks for reduced motion
//   (prefers-reduced-motion) and pauses on hover or focus.
export default class extends Controller {
  static targets = ["slide", "track", "status"]
  static values = { interval: { type: Number, default: 5000 } }

  connect() {
    this.index = 0
    this.timer = null
    this.show(this.index)
    this.start()

    if (this.hasReducedMotionPreference) {
      this.stop()
    }
  }

  disconnect() {
    this.stop()
  }

  start() {
    this.stop()
    this.timer = setInterval(() => this.next(), this.intervalValue)
  }

  stop() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  get hasReducedMotionPreference() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  get slideCount() {
    return this.slideTargets.length
  }

  next() {
    this.show((this.index + 1) % this.slideCount)
  }

  previous() {
    this.show((this.index - 1 + this.slideCount) % this.slideCount)
  }

  show(index) {
    this.index = index
    this.slideTargets.forEach((slide, position) => {
      slide.toggleAttribute("hidden", position !== index)
      slide.setAttribute("aria-hidden", position === index ? "false" : "true")
    })

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = `${this.index + 1} / ${this.slideCount}`
    }
  }

  pause() {
    this.stop()
  }

  resume() {
    if (!this.hasReducedMotionPreference) {
      this.start()
    }
  }
}
