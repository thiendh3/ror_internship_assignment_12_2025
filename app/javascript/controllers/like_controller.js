import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["likeBtn", "likesCount", "icon"];

  connect() {
    this.micropostId = this.element.dataset.micropostId;
  }

  async toggle(event) {
    event.preventDefault();

    const isLiked = this.element.classList.contains("liked");
    const url = isLiked
      ? `/microposts/${this.micropostId}/likes/${this.element.dataset.likeId}`
      : `/microposts/${this.micropostId}/likes`;

    const method = isLiked ? "DELETE" : "POST";

    try {
      const response = await fetch(url, {
        method: method,
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        },
      });

      const data = await response.json();

      if (data.success) {
        // Update UI
        this.element.classList.toggle("liked");

        // Update icon
        const icon = this.element.querySelector("i");
        if (this.element.classList.contains("liked")) {
          icon.classList.remove("far");
          icon.classList.add("fas");
          this.element.dataset.likeId = data.like_id;
        } else {
          icon.classList.remove("fas");
          icon.classList.add("far");
          delete this.element.dataset.likeId;
        }

        // Update count
        const countElement = document.querySelector(
          `#micropost-${this.micropostId} .likes-count`
        );
        if (countElement) {
          countElement.dataset.count = data.likes_count;
          countElement.innerHTML = `<i class="far fa-heart"></i> ${data.likes_count}`;
        }
      }
    } catch (error) {
      console.error("Error toggling like:", error);
    }
  }
}
