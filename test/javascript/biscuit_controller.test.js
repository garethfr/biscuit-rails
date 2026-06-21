import { describe, it, expect, vi, beforeEach, afterEach } from "vitest"
import { Application } from "@hotwired/stimulus"
import BiscuitController from "../../app/assets/javascripts/biscuit/biscuit_controller.js"

function buildFixture({ categories = ["analytics", "marketing"] } = {}) {
  document.body.innerHTML = `
    <div data-controller="biscuit"
         data-biscuit-endpoint-value="/biscuit/consent"
         data-biscuit-csrf-token-value="test-token"
         data-biscuit-already-consented-value="false">

      <div data-biscuit-target="banner"></div>

      <div data-biscuit-target="preferencesPanel" hidden>
        ${categories.map(cat =>
          `<input type="checkbox"
                  data-biscuit-target="categoryCheckbox"
                  data-category="${cat}"
                  checked>`
        ).join("")}
        <button id="save" data-action="click->biscuit#savePreferences">Save</button>
      </div>

      <button id="accept" data-action="click->biscuit#acceptAll">Accept all</button>
      <button id="reject" data-action="click->biscuit#rejectAll">Reject all</button>
      <button data-biscuit-target="manageLink" hidden>Cookie settings</button>
    </div>
  `
}

function mockFetch(ok = true) {
  vi.spyOn(globalThis, "fetch").mockResolvedValue({ ok })
}

async function click(id) {
  document.getElementById(id).click()
  await new Promise(resolve => setTimeout(resolve, 0))
}

function bannerTarget()     { return document.querySelector("[data-biscuit-target='banner']") }
function manageLinkTarget() { return document.querySelector("[data-biscuit-target='manageLink']") }

describe("BiscuitController", () => {
  let application

  beforeEach(async () => {
    application = Application.start()
    application.register("biscuit", BiscuitController)
    await new Promise(resolve => setTimeout(resolve, 0))
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    vi.restoreAllMocks()
  })

  describe("biscuit:consent-given event", () => {
    it("is dispatched after acceptAll with all categories true", async () => {
      buildFixture({ categories: ["analytics", "marketing"] })
      await new Promise(resolve => setTimeout(resolve, 0))
      mockFetch(true)

      const events = []
      document.addEventListener("biscuit:consent-given", e => events.push(e), true)

      await click("accept")

      expect(events).toHaveLength(1)
      expect(events[0].detail.categories).toEqual({ analytics: true, marketing: true })
    })

    it("is dispatched after rejectAll with all categories false", async () => {
      buildFixture({ categories: ["analytics", "marketing"] })
      await new Promise(resolve => setTimeout(resolve, 0))
      mockFetch(true)

      const events = []
      document.addEventListener("biscuit:consent-given", e => events.push(e), true)

      await click("reject")

      expect(events).toHaveLength(1)
      expect(events[0].detail.categories).toEqual({ analytics: false, marketing: false })
    })

    it("is dispatched after savePreferences reflecting checkbox state", async () => {
      buildFixture({ categories: ["analytics", "marketing"] })
      await new Promise(resolve => setTimeout(resolve, 0))
      mockFetch(true)

      document.querySelector('[data-category="marketing"]').checked = false

      const events = []
      document.addEventListener("biscuit:consent-given", e => events.push(e), true)

      await click("save")

      expect(events).toHaveLength(1)
      expect(events[0].detail.categories).toEqual({ analytics: true, marketing: false })
    })

    it("bubbles so ancestor elements can listen without targeting the banner", async () => {
      buildFixture()
      await new Promise(resolve => setTimeout(resolve, 0))
      mockFetch(true)

      const outerEvents = []
      document.body.addEventListener("biscuit:consent-given", e => outerEvents.push(e))

      await click("accept")

      expect(outerEvents).toHaveLength(1)
    })

    it("is NOT dispatched when the consent POST returns a non-ok response", async () => {
      buildFixture()
      await new Promise(resolve => setTimeout(resolve, 0))
      mockFetch(false)

      const events = []
      document.addEventListener("biscuit:consent-given", e => events.push(e), true)

      await click("accept")

      expect(events).toHaveLength(0)
    })
  })

  describe("post-consent UI", () => {
    it("hides the banner after consent", async () => {
      buildFixture()
      await new Promise(resolve => setTimeout(resolve, 0))
      mockFetch(true)

      await click("accept")

      expect(bannerTarget().hidden).toBe(true)
    })

    it("shows the manage link after consent", async () => {
      buildFixture()
      await new Promise(resolve => setTimeout(resolve, 0))
      mockFetch(true)

      await click("accept")

      expect(manageLinkTarget().hidden).toBe(false)
    })
  })
})
