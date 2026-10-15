import { Controller } from "@hotwired/stimulus"

// Keeps empty fields out of the query string, so a search with no guide chosen is /?q=callbacks
// rather than /?q=callbacks&guide=. A disabled control is left out of the submission.
export default class extends Controller {
  submit() {
    const empty = Array.from(this.element.elements).filter((field) => field.name && field.value === "")
    empty.forEach((field) => (field.disabled = true))
    // Turbo reads the form after this handler returns; the fields come back once it has.
    setTimeout(() => empty.forEach((field) => (field.disabled = false)))
  }
}
