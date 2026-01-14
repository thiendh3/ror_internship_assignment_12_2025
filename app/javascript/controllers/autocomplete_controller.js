import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["input", "results"];
	static values = { url: String };

	connect() {
		this.resultsTarget.hidden = true;
	}

	search() {
		clearTimeout(this.timeout);
		this.timeout = setTimeout(() => {
			this.performSearch();
		}, 300);
	}

	async performSearch() {
		const query = this.inputTarget.value;

		if (query.length < 1) {
			this.resultsTarget.hidden = true;
			this.resultsTarget.innerHTML = "";
			return;
		}

		const searchFieldSelect = this.element.querySelector(
			'select[name="search_field"]'
		);
		const searchField = searchFieldSelect
			? searchFieldSelect.value
			: "name";

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
			this.renderResults(data);
		} catch (error) {
			console.error("Autocomplete error:", error);
		}
	}

	renderResults(data) {
		if (data.queries.length === 0 && data.users.length === 0) {
			this.resultsTarget.hidden = true;
			return;
		}

		let html = "";

		// 1. Search Suggestions
		if (data.queries.length > 0) {
			html += `<div class="autocomplete-header">Search Suggestions</div>`;
			data.queries.forEach((q) => {
				html += `
        <a href="#" class="list-group-item query-suggestion-item" data-action="click->autocomplete#selectQuery">
          <span class="glyphicon glyphicon-search"></span> <span>${this.escapeHtml(
				q
			)}</span>
        </a>`;
			});
		}

		// 2. People Results
		if (data.users.length > 0) {
			html += `<div class="autocomplete-header">People</div>`;
			data.users.forEach((user) => {
				const emailHtml = user.email
					? `<small class="text-info">${this.escapeHtml(
							user.email
					  )}</small>`
					: "";
				html += `
        <a href="${user.url}" class="list-group-item user-result-item">
          <img src="${
				user.gravatar_url
			}" class="gravatar" style="width: 36px; height: 36px;">
          <div class="media-body">
            <strong>${this.escapeHtml(user.name)}</strong>
            ${emailHtml}
          </div>
        </a>`;
			});
		}

		this.resultsTarget.innerHTML = html;
		this.resultsTarget.hidden = false;
	}

	// Fills the input and submits the form when a query suggestion is clicked
	selectQuery(event) {
		event.preventDefault();
		const query = event.currentTarget.textContent.trim();
		this.inputTarget.value = query;
		this.resultsTarget.hidden = true;
		this.inputTarget.form.submit();
	}

	blur(event) {
		// Timeout allows clicks on suggestions to register before the list disappears
		setTimeout(() => {
			this.resultsTarget.hidden = true;
		}, 200);
	}

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
