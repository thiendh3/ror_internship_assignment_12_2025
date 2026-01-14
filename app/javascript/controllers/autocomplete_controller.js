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

		try {
			const response = await fetch(
				`${this.urlValue}?query=${encodeURIComponent(query)}`,
				{
					headers: { Accept: "application/json" },
				}
			);
			const users = await response.json();
			this.renderResults(users);
		} catch (error) {
			console.error("Autocomplete error:", error);
		}
	}

	renderResults(users) {
		if (users.length === 0) {
			this.resultsTarget.hidden = true;
			return;
		}

		const html = users.map(user => `
      <a href="${user.url}" class="list-group-item autocomplete-item" style="display: flex; align-items: center; gap: 10px;">
        
        <img src="${user.gravatar_url}" alt="${this.escapeHtml(user.name)}" class="gravatar" style="border-radius: 50%; width: 40px; height: 40px; border: 1px solid #ddd;">
        
        <div class="media-body">
          <strong>${this.escapeHtml(user.name)}</strong>
          <br>
          <small class="text-muted" style="font-size: 0.85em;">
             Following: ${user.following_count} | Followers: ${user.followers_count}
          </small>
        </div>
      </a>
    `).join("")

		this.resultsTarget.innerHTML = html;
		this.resultsTarget.hidden = false;
	}

	blur(event) {
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
