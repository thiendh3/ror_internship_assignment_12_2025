import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "suggestions"];

  connect() {
    this.mentionPattern = /@(\w*)$/;
    this.hashtagPattern = /#(\w*)$/;
    this.selectedIndex = -1;
  }

  async onInput(event) {
    const textarea = event.target;
    const cursorPosition = textarea.selectionStart;
    const textBeforeCursor = textarea.value.substring(0, cursorPosition);

    // Check for @ mention
    const mentionMatch = textBeforeCursor.match(this.mentionPattern);
    if (mentionMatch) {
      const query = mentionMatch[1];
      await this.showMentionSuggestions(query, textarea);
      return;
    }

    // Check for # hashtag
    const hashtagMatch = textBeforeCursor.match(this.hashtagPattern);
    if (hashtagMatch) {
      const query = hashtagMatch[1];
      await this.showHashtagSuggestions(query, textarea);
      return;
    }

    // Hide suggestions if no match
    this.hideSuggestions();
  }

  async showMentionSuggestions(query, textarea) {
    try {
      const response = await fetch(
        `/users/autocomplete?q=${encodeURIComponent(query)}`
      );
      const data = await response.json();

      if (data.users && data.users.length > 0) {
        this.renderSuggestions(data.users, "mention", textarea);
      } else {
        this.hideSuggestions();
      }
    } catch (error) {
      console.error("Error fetching user suggestions:", error);
    }
  }

  async showHashtagSuggestions(query, textarea) {
    try {
      const response = await fetch(
        `/microposts/autocomplete?q=${encodeURIComponent(query)}`
      );
      const data = await response.json();

      if (data.suggestions && data.suggestions.length > 0) {
        this.renderSuggestions(data.suggestions, "hashtag", textarea);
      } else {
        this.hideSuggestions();
      }
    } catch (error) {
      console.error("Error fetching hashtag suggestions:", error);
    }
  }

  renderSuggestions(items, type, textarea) {
    // Create or get suggestions container
    let container = document.getElementById("autocomplete-suggestions");
    if (!container) {
      container = document.createElement("div");
      container.id = "autocomplete-suggestions";
      container.className = "autocomplete-suggestions";
      textarea.parentNode.appendChild(container);
    }

    // Position container below textarea
    const rect = textarea.getBoundingClientRect();
    container.style.position = "absolute";
    container.style.left = `${rect.left}px`;
    container.style.top = `${rect.bottom + window.scrollY}px`;
    container.style.width = `${rect.width}px`;

    // Render suggestions
    this.selectedIndex = -1;
    container.innerHTML = items
      .map((item, index) => {
        if (type === "mention") {
          return `<div class="suggestion-item" data-index="${index}" data-value="@${item.name}">
          <i class="fas fa-user me-2"></i>@${item.name}
          <small class="text-muted ms-2">${item.email}</small>
        </div>`;
        } else {
          return `<div class="suggestion-item" data-index="${index}" data-value="#${item}">
          <i class="fas fa-hashtag me-2"></i>${item}
        </div>`;
        }
      })
      .join("");

    // Add click handlers
    container.querySelectorAll(".suggestion-item").forEach((item) => {
      item.addEventListener("click", (e) => {
        this.selectSuggestion(e.currentTarget.dataset.value, textarea);
      });
    });

    container.style.display = "block";
    this.currentTextarea = textarea;
  }

  hideSuggestions() {
    const container = document.getElementById("autocomplete-suggestions");
    if (container) {
      container.style.display = "none";
    }
    this.selectedIndex = -1;
  }

  onKeyDown(event) {
    const container = document.getElementById("autocomplete-suggestions");
    if (!container || container.style.display === "none") return;

    const items = container.querySelectorAll(".suggestion-item");
    if (items.length === 0) return;

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1);
        this.highlightItem(items);
        break;
      case "ArrowUp":
        event.preventDefault();
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0);
        this.highlightItem(items);
        break;
      case "Enter":
        if (this.selectedIndex >= 0) {
          event.preventDefault();
          this.selectSuggestion(
            items[this.selectedIndex].dataset.value,
            event.target
          );
        }
        break;
      case "Escape":
        event.preventDefault();
        this.hideSuggestions();
        break;
    }
  }

  highlightItem(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add("selected");
      } else {
        item.classList.remove("selected");
      }
    });
  }

  selectSuggestion(value, textarea) {
    const cursorPosition = textarea.selectionStart;
    const textBeforeCursor = textarea.value.substring(0, cursorPosition);
    const textAfterCursor = textarea.value.substring(cursorPosition);

    // Replace the partial mention/hashtag with the selected value
    const newTextBefore = textBeforeCursor.replace(/[@#]\w*$/, value + " ");
    textarea.value = newTextBefore + textAfterCursor;

    // Set cursor position after the inserted text
    const newPosition = newTextBefore.length;
    textarea.setSelectionRange(newPosition, newPosition);
    textarea.focus();

    this.hideSuggestions();
  }

  disconnect() {
    this.hideSuggestions();
  }
}
