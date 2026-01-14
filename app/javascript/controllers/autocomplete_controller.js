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

		// 1. Render Search Suggestions (Queries)
		if (data.queries.length > 0) {
			html += `<div class="autocomplete-header">Search Suggestions</div>`;
			data.queries.forEach((q) => {
				html += `
          <a href="#" class="list-group-item" data-action="click->autocomplete#selectQuery">
            <span class="glyphicon glyphicon-search text-muted"></span> ${this.escapeHtml(
				q
			)}
          </a>`;
			});
		}

		// 2. Render Instant Results (People)
		if (data.users.length > 0) {
			html += `<div class="autocomplete-header">People</div>`;
			html += data.users
				.map((user) => {
					const emailHtml = user.email
						? `<br><small class="text-info"><span class="glyphicon glyphicon-envelope"></span> ${this.escapeHtml(
								user.email
						  )}</small>`
						: "";

					return `
            <a href="${
				user.url
			}" class="list-group-item autocomplete-item" style="display: flex; align-items: center; gap: 10px;">
              <img src="${user.gravatar_url}" alt="${this.escapeHtml(
						user.name
					)}" 
                   class="gravatar" style="border-radius: 50%; width: 32px; height: 32px; border: 1px solid #ddd; flex-shrink: 0;">
              <div class="media-body">
                <strong>${this.escapeHtml(user.name)}</strong>
                ${emailHtml}
                <br>
                <small class="text-muted" style="font-size: 0.8em;">
                   Following: ${user.following_count} | Followers: ${
						user.followers_count
					}
                </small>
              </div>
            </a>`;
				})
				.join("");
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
