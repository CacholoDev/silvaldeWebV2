// Applies the visitor's colour theme before the page paints.
//
// This file is loaded synchronously in the <head>, so the `dark` class is
// already on <html> when the body renders: the visitor never sees a flash of
// the light theme before the theme toggle script takes over.
//
// The default is the light theme. The stored choice wins; when there is no
// stored choice, the operating system preference is ignored on purpose (the
// shop starts light).
const STORAGE_KEY = "silvalde-theme"

function applyTheme() {
  let stored = null

  try {
    stored = window.localStorage.getItem(STORAGE_KEY)
  } catch (error) {
    // Private browsing or blocked storage: fall back to the light theme.
    return
  }

  const isDark = stored === "dark"
  document.documentElement.classList.toggle("dark", isDark)
  document.documentElement.style.colorScheme = isDark ? "dark" : "light"
}

applyTheme()
