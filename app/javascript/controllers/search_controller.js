import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results", "suggestions"];

  connect() {
    this.debounceTimer = null;
  }

  search(event) {
    clearTimeout(this.debounceTimer);

    const query = event.target.value.trim();

    if (query.length < 2) {
      this.clearSuggestions();
      return;
    }

    this.debounceTimer = setTimeout(() => {
      this.fetchSuggestions(query);
    }, 300);
  }

  async fetchSuggestions(query) {
    try {
      const response = await fetch(
        `/microposts/autocomplete?q=${encodeURIComponent(query)}`,
        {
          headers: {
            Accept: "application/json",
          },
        }
      );

      const data = await response.json();
      this.displaySuggestions(data.suggestions);
    } catch (error) {
      console.error("Error fetching suggestions:", error);
    }
  }

  displaySuggestions(suggestions) {
    if (!this.hasSuggestionsTarget) return;

    if (suggestions.length === 0) {
      this.clearSuggestions();
      return;
    }

    this.suggestionsTarget.innerHTML = suggestions
      .map(
        (suggestion) => `
        <div class="suggestion-item" data-action="click->search#selectSuggestion">
          ${this.highlightQuery(suggestion)}
        </div>
      `
      )
      .join("");

    this.suggestionsTarget.classList.add("show");
  }

  selectSuggestion(event) {
    const suggestion = event.currentTarget.textContent.trim();
    if (this.hasInputTarget) {
      this.inputTarget.value = suggestion;
    }
    this.clearSuggestions();
    this.submitSearch();
  }

  clearSuggestions() {
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.innerHTML = "";
      this.suggestionsTarget.classList.remove("show");
    }
  }

  submitSearch() {
    if (this.hasInputTarget) {
      const query = this.inputTarget.value.trim();
      if (query) {
        window.location.href = `/microposts/search?q=${encodeURIComponent(
          query
        )}`;
      }
    }
  }

  highlightQuery(text) {
    if (!this.hasInputTarget) return text;

    const query = this.inputTarget.value.trim();
    const regex = new RegExp(`(${query})`, "gi");
    return text.replace(regex, "<strong>$1</strong>");
  }
}
