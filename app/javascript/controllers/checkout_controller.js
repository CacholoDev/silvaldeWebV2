import { Controller } from "@hotwired/stimulus"

// Focus management for the checkout form.
//
// After a failed submit the server re-renders the form with an error summary
// (role="alert"). The customer must land on it: the errors are the reason
// the order did not go through. Moving the focus to the summary makes screen
// readers announce it and puts the keyboard at the top of the form, ready to
// fix the field.
//
// The summary is the fallback: when the browser's own validation blocks the
// submit (an empty required field), it already moves the focus to the first
// invalid field, and this controller does not interfere.
//
// Without JavaScript the summary stays visible and readable at the top of
// the page: the server always renders it.
export default class extends Controller {
  static targets = ["summary"]

  connect() {
    this.summaryTarget.setAttribute("tabindex", "-1")
    this.summaryTarget.focus()
  }
}
