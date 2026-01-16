import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["input", "results"];
	static values = { url: String };

	connect() {
		this.resultsTarget.hidden = true;
	}

	updateParams() {
		this.search();
	}

    // debounced user input and send requests to server
	search() {
		clearTimeout(this.timeout);
		this.timeout = setTimeout(() => {
			this.performSearch();
		}, 300);
	}

    // the actual search
	async performSearch() {
		const query = this.inputTarget.value.trim();

		if (query.length < 1) {
			this.resultsTarget.hidden = true;
			return;
		}

		const searchField =
			document.querySelector('select[name="search_field"]')?.value ||
			"name";

		try {
			const response = await fetch(
				`${this.urlValue}?query=${encodeURIComponent(
					query
				)}&search_field=${searchField}`,
				{
					headers: { Accept: "application/json" },
				}
			);
			const data = await response.json();
			this.renderResults(data.queries);
		} catch (error) {
			console.error("Autocomplete error:", error);
		}
	}

    // build the autocomplete lists
	renderResults(queries) {
		if (!queries || queries.length === 0) {
			this.resultsTarget.hidden = true;
			return;
		}

		let html = `<div class="list-group" style="margin-bottom: 0; box-shadow: 0 6px 12px rgba(0,0,0,.175);">`;

		queries.forEach((term) => {
			html += `
        <a href="#" class="list-group-item" data-action="click->autocomplete#selectQuery">
          <span class="glyphicon glyphicon-search text-muted" style="margin-right: 10px;"></span>
          ${this.escapeHtml(term)}
        </a>
      `;
		});

		html += `</div>`;

		this.resultsTarget.innerHTML = html;
		this.resultsTarget.hidden = false;
	}

    // fill the search bar and submit the search form when select an autocomplete item
	selectQuery(event) {
		event.preventDefault();
		this.inputTarget.value = event.currentTarget.innerText.trim();
		this.resultsTarget.hidden = true;
		this.inputTarget.form.requestSubmit();
	}

    // hide autocomplete list when click outside the search bar
	blur() {
		setTimeout(() => {
			this.resultsTarget.hidden = true;
		}, 200);
	}

    // escape special characters to prevent XSS attacking
	escapeHtml(text) {
		if (!text) return "";
		return text
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;")
			.replace(/"/g, "&quot;")
			.replace(/'/g, "&#039;");
	}
}
