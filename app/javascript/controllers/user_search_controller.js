import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["query", "results", "filter"];

  connect() {
    // Debounce timer
    this.timeout = null;
  }

  search() {
    // Clear previous timeout
    clearTimeout(this.timeout);

    // Set new timeout for debounced search
    this.timeout = setTimeout(() => {
      this.performSearch();
    }, 300);
  }

  async performSearch() {
    const query = this.queryTarget.value.trim();

    if (query.length === 0) {
      this.clearResults();
      return;
    }

    try {
      // Build search URL with filters
      const url = new URL("/users/search", window.location.origin);
      url.searchParams.append("q", query);
      url.searchParams.append("format", "json");

      // Add filter if present
      if (this.hasFilterTarget) {
        const filterValue = this.filterTarget.value;
        if (filterValue === "following") {
          url.searchParams.append("following", "true");
        } else if (filterValue === "followers") {
          url.searchParams.append("followers", "true");
        }
      }

      const response = await fetch(url, {
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        },
      });

      const data = await response.json();
      this.displayResults(data);
    } catch (error) {
      console.error("Error searching users:", error);
    }
  }

  displayResults(data) {
    if (!this.hasResultsTarget) return;

    if (data.users.length === 0) {
      this.resultsTarget.innerHTML = '<p class="text-muted">No users found</p>';
      return;
    }

    const usersHtml = data.users
      .map(
        (user) => `
      <div class="user-search-result" data-user-id="${user.id}">
        <div class="user-info">
          <a href="/users/${user.id}">${user.name}</a>
          <span class="text-muted">${user.email}</span>
        </div>
        <div class="user-stats">
          <span>${user.followers_count} followers</span>
          <span>${user.following_count} following</span>
        </div>
      </div>
    `
      )
      .join("");

    this.resultsTarget.innerHTML = usersHtml;
  }

  clearResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = "";
    }
  }

  filterChanged() {
    if (this.queryTarget.value.trim().length > 0) {
      this.performSearch();
    }
  }
}
