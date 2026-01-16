import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = { url: String };

	load(event) {
		event.preventDefault();
		this.cleanup();

		fetch(this.urlValue)
			.then((response) => response.text())
			.then((html) => {
				document.body.insertAdjacentHTML("beforeend", html);
				if (window.jQuery) {
					window.jQuery("#editProfileModal").modal("show");
				}
			})
			.catch((err) => console.error("Error loading edit modal:", err));
	}

	cleanup() {
		const modal = document.getElementById("editProfileModal");
		if (modal) {
			modal.remove();
		}
		document
			.querySelectorAll(".modal-backdrop")
			.forEach((el) => el.remove());
		document.body.classList.remove("modal-open");
	}
}
