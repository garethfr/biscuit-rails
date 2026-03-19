import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preferencesPanel", "categoryCheckbox", "manageLink"]
  static values  = {
    endpoint:         String,
    csrfToken:        String,
    position:         { type: String, default: "bottom" },
    alreadyConsented: { type: Boolean, default: false }
  }

  connect() {
    if (this.alreadyConsentedValue) {
      this.#hideBanner()
      this.#showManageLink()
    }
  }

  acceptAll() {
    this.#post(this.#allCategories(true))
  }

  rejectAll() {
    this.#post(this.#allCategories(false))
  }

  togglePreferences() {
    const panel  = this.preferencesPanelTarget
    const isOpen = panel.classList.contains("biscuit-preferences--open")
    panel.classList.toggle("biscuit-preferences--open", !isOpen)
    panel.hidden = isOpen

    // Update aria-expanded on the toggle button
    const btn = this.element.querySelector("[data-action~='biscuit#togglePreferences']")
    if (btn) btn.setAttribute("aria-expanded", String(!isOpen))
  }

  savePreferences() {
    const categories = {}
    this.categoryCheckboxTargets.forEach(cb => {
      categories[cb.dataset.category] = cb.checked
    })
    this.#post(categories)
  }

  reopen() {
    this.#showBanner()
    this.#hideManageLink()
  }

  // Private

  #allCategories(value) {
    const categories = {}
    this.categoryCheckboxTargets.forEach(cb => {
      categories[cb.dataset.category] = value
    })
    return categories
  }

  async #post(categories) {
    try {
      const response = await fetch(this.endpointValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token":  this.csrfTokenValue
        },
        body: JSON.stringify({ categories })
      })
      if (response.ok) {
        this.#hideBanner()
        this.#showManageLink()
      }
    } catch (error) {
      console.error("[Biscuit] Failed to save consent:", error)
    }
  }

  #hideBanner()     { this.element.hidden = true;  this.element.setAttribute("aria-hidden", "true") }
  #showBanner()     { this.element.hidden = false; this.element.removeAttribute("aria-hidden") }
  #showManageLink() { if (this.hasManageLinkTarget) this.manageLinkTarget.hidden = false }
  #hideManageLink() { if (this.hasManageLinkTarget) this.manageLinkTarget.hidden = true }
}
