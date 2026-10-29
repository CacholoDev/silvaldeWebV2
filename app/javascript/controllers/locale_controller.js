import { Controller } from "@hotwired/stimulus"

// Language dropdown.
//
// - A real <button> opens the menu, so it works with the keyboard (Enter and
//   Space) and announces its state to screen readers (aria-expanded).
// - The mouse can also open it by hovering the globe icon.
// - The hover handlers live on the wrapper (button + menu), not on the
//   button: with the handler on the button, moving the pointer towards the
//   menu fired `mouseleave` and closed the dropdown before the visitor
//   could reach a language.
// - Clicking outside or pressing Escape closes it.
// - Each option is a real form button, so switching the language posts to
//   the existing locale endpoint and works without JavaScript.
export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    this.close()
  }

  disconnect() {
    this.close()
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.menuTarget.hidden = false
    this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    if (!this.hasMenuTarget) return

    this.menuTarget.hidden = true
    this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  // Close when clicking anywhere outside the dropdown.
  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  // Close when the keyboard focus leaves the dropdown (tabbing past the
  // last option), so the menu does not stay open behind the page.
  closeOnFocusOut(event) {
    if (this.menuTarget.hidden) return

    const next = event.relatedTarget
    if (next && this.element.contains(next)) return

    this.close()
  }

  // Close with Escape and return the focus to the button that opened it.
  closeOnEscape(event) {
    if (event.key !== "Escape") return
    if (this.menuTarget.hidden) return

    this.close()
    this.toggleTarget.focus()
  }
}
