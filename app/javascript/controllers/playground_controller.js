import { Controller } from "@hotwired/stimulus"

// Submits the playground form a moment after the last keystroke, and fills it from a preset.
// The form targets a Turbo Frame, so only the results re-render and the inputs keep focus.
export default class extends Controller {
  static targets = ["text", "query"]
  static values = { delay: { type: Number, default: 250 } }

  schedule() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  preset({ params: { text, query } }) {
    clearTimeout(this.timer)
    this.textTarget.value = text
    this.queryTarget.value = query
    this.element.requestSubmit()
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
