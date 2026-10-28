import { Controller } from "@hotwired/stimulus"

// Light/dark theme toggle.
//
// - The theme is a `dark` class on <html>, applied by app/javascript/theme.js
//   before the page paints (so there is no flash of the wrong theme).
// - The default is the light theme. Only an explicit choice stored by the
//   visitor switches to dark.
// - The choice is kept in localStorage, so it survives visits.
// - The button shows the icon of the theme it switches TO (a sun in dark
//   mode, a moon in light mode) and labels itself for screen readers.
export default class extends Controller {
  static values = {
    storageKey: { type: String, default: "silvalde-theme" }
  }

  connect() {
    this.apply(this.storedTheme())
    this.updateButton()
  }

  toggle() {
    const next = this.isDark ? "light" : "dark"

    this.apply(next)
    this.store(next)
    this.updateButton()
  }

  get isDark() {
    return document.documentElement.classList.contains("dark")
  }

  // Only an explicit stored choice counts: the shop starts in light mode.
  storedTheme() {
    try {
      return window.localStorage.getItem(this.storageKeyValue) === "dark" ? "dark" : "light"
    } catch (error) {
      return "light"
    }
  }

  store(theme) {
    try {
      window.localStorage.setItem(this.storageKeyValue, theme)
    } catch (error) {
      // Storage blocked (private browsing): the theme still changes for
      // this page view, it just will not be remembered.
    }
  }

  apply(theme) {
    const isDark = theme === "dark"

    document.documentElement.classList.toggle("dark", isDark)
    document.documentElement.style.colorScheme = isDark ? "dark" : "light"
  }

  updateButton() {
    const dark = this.isDark

    // Query the icons directly instead of relying on the Stimulus target
    // getters: the button must always show the icon of the theme it switches
    // TO, even if the targets are declared outside this controller.
    const iconDark = this.element.querySelector("[data-theme-target='iconDark']")
    const iconLight = this.element.querySelector("[data-theme-target='iconLight']")

    if (iconDark) iconDark.hidden = dark
    if (iconLight) iconLight.hidden = !dark

    const label = dark
      ? this.element.dataset.labelLight || "Cambiar a modo claro"
      : this.element.dataset.labelDark || "Cambiar a modo oscuro"

    this.element.setAttribute("aria-label", label)
    this.element.setAttribute("aria-pressed", String(dark))
  }
}
