import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = { url: String };

	connect() {
		this.boundCleanup = this.cleanup.bind(this);

		document.addEventListener("turbo:before-cache", this.boundCleanup);
	}

	disconnect() {
		document.removeEventListener("turbo:before-cache", this.boundCleanup);

		this.cleanup();
	}

	load(event) {
		event.preventDefault();

		this.cleanup();

		fetch(this.urlValue)
			.then((response) => response.text())
			.then((html) => {
				document.body.insertAdjacentHTML("beforeend", html);

				if (window.jQuery) {
					window.jQuery("#userPreviewModal").modal("show");
				}
			})
			.catch((err) => console.error("Error loading preview:", err));
	}

	cleanup() {
		const modal = document.getElementById("userPreviewModal");
		if (modal) {
			modal.remove();
		}

		document.querySelectorAll(".modal-backdrop").forEach((backdrop) => {
			backdrop.remove();
		});

		document.body.classList.remove("modal-open");
		document.body.style.paddingRight = "";
	}
}
