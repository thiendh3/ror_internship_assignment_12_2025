import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = { url: String };

	load(event) {
		event.preventDefault();

		// 1. Remove any existing modal from the DOM to avoid ID conflicts
		this.cleanup();

		// 2. Fetch and append the new modal
		fetch(this.urlValue)
			.then((response) => response.text())
			.then((html) => {
				document.body.insertAdjacentHTML("beforeend", html);

				// 3. Show it using Bootstrap 3 syntax
				if (window.jQuery) {
					window.jQuery("#userPreviewModal").modal("show");
				}
			})
			.catch((err) => console.error("Error loading preview:", err));
	}

	// Helper to remove the modal element if it exists
	cleanup() {
		const modal = document.getElementById("userPreviewModal");
		if (modal) {
			modal.remove();
		}

		// Safety check: sometimes backdrop remains if things get desynced
		const backdrop = document.querySelector(".modal-backdrop");
		if (backdrop) {
			backdrop.remove();
		}
		document.body.classList.remove("modal-open");
	}
}
