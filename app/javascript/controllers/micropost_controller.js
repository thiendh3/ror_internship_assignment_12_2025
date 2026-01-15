import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "content",
    "form",
    "display",
    "editBtn",
    "cancelBtn",
    "saveBtn",
  ];

  connect() {
    this.micropostId = this.element.dataset.micropostId;
  }

  edit(event) {
    event.preventDefault();

    const contentElement = this.element.querySelector(".micropost-content");
    const currentContent = contentElement.dataset.content;

    // Show edit form
    contentElement.innerHTML = `
      <form data-action="submit->micropost#update" class="micropost-edit-form">
        <textarea class="form-control" name="content" rows="3">${this.escapeHTML(
          currentContent
        )}</textarea>
        <div class="mt-2">
          <button type="submit" class="btn btn-primary btn-sm">Save</button>
          <button type="button" class="btn btn-secondary btn-sm" data-action="click->micropost#cancelEdit">Cancel</button>
        </div>
      </form>
    `;
  }

  cancelEdit(event) {
    event.preventDefault();
    location.reload(); // Simple way to restore original content
  }

  async update(event) {
    event.preventDefault();

    const form = event.target;
    const content = form.querySelector('textarea[name="content"]').value;

    try {
      const response = await fetch(`/microposts/${this.micropostId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        },
        body: JSON.stringify({ micropost: { content: content } }),
      });

      const data = await response.json();

      if (data.success) {
        // Update content display
        const contentElement = this.element.querySelector(".micropost-content");
        contentElement.dataset.content = data.micropost.content;

        // Reload to show updated content with formatted hashtags/mentions
        location.reload();
      } else {
        alert("Error updating micropost: " + data.errors.join(", "));
      }
    } catch (error) {
      console.error("Error updating micropost:", error);
      alert("Error updating micropost");
    }
  }

  async delete(event) {
    event.preventDefault();

    if (!confirm("Are you sure you want to delete this micropost?")) return;

    try {
      const response = await fetch(`/microposts/${this.micropostId}`, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        },
      });

      const data = await response.json();

      if (data.success) {
        // Remove micropost from DOM with animation
        this.element.style.transition = "opacity 0.3s";
        this.element.style.opacity = "0";
        setTimeout(() => this.element.remove(), 300);
      } else {
        alert("Error deleting micropost");
      }
    } catch (error) {
      console.error("Error deleting micropost:", error);
      alert("Error deleting micropost");
    }
  }

  share(event) {
    event.preventDefault();

    const url = `${window.location.origin}/microposts/${this.micropostId}`;

    // Copy to clipboard
    navigator.clipboard
      .writeText(url)
      .then(() => {
        alert("Link copied to clipboard!");
      })
      .catch((err) => {
        console.error("Error copying link:", err);
        // Fallback: show the URL
        prompt("Copy this link:", url);
      });
  }

  shareTwitter(event) {
    event.preventDefault();
    const micropostId =
      event.currentTarget.dataset.micropostId || this.micropostId;
    const url = `${window.location.origin}/microposts/${micropostId}`;
    const contentElement = document.querySelector(
      `#micropost-${micropostId} .micropost-content`
    );
    const text = contentElement
      ? contentElement.textContent.trim().substring(0, 100)
      : "";
    const twitterUrl = `https://twitter.com/intent/tweet?url=${encodeURIComponent(
      url
    )}&text=${encodeURIComponent(text)}`;
    window.open(twitterUrl, "_blank", "width=550,height=420");
  }

  shareFacebook(event) {
    event.preventDefault();
    const micropostId =
      event.currentTarget.dataset.micropostId || this.micropostId;
    const url = `${window.location.origin}/microposts/${micropostId}`;
    const facebookUrl = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(
      url
    )}`;
    window.open(facebookUrl, "_blank", "width=550,height=420");
  }

  copyLink(event) {
    event.preventDefault();
    const micropostId =
      event.currentTarget.dataset.micropostId || this.micropostId;
    const url = `${window.location.origin}/microposts/${micropostId}`;

    navigator.clipboard
      .writeText(url)
      .then(() => {
        const link = event.currentTarget;
        const originalHTML = link.innerHTML;
        link.innerHTML = '<i class="fa fa-check"></i> Copied!';
        link.classList.add("text-success");

        setTimeout(() => {
          link.innerHTML = originalHTML;
          link.classList.remove("text-success");
        }, 2000);
      })
      .catch((err) => {
        console.error("Error copying link:", err);
        prompt("Copy this link:", url);
      });
  }

  escapeHTML(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }
}
