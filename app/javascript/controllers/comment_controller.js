import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "commentsList", "content"];

  connect() {
    this.micropostId = this.element.dataset.micropostId;
    // Listen to Bootstrap 3 collapse events
    $(`#comments-section-${this.micropostId}`).on("show.bs.collapse", () => {
      this.load();
    });
  }

  async load() {
    // Only load if not already loaded
    const commentsList = document.querySelector(
      `#comments-list-${this.micropostId}`
    );
    if (commentsList && !commentsList.dataset.loaded) {
      await this.loadComments();
      commentsList.dataset.loaded = "true";
    }
  }

  async loadComments() {
    const commentsList = document.querySelector(
      `#comments-list-${this.micropostId}`
    );

    try {
      const response = await fetch(`/microposts/${this.micropostId}/comments`, {
        headers: {
          Accept: "application/json",
        },
      });

      const comments = await response.json();
      this.renderComments(comments);
    } catch (error) {
      console.error("Error loading comments:", error);
      if (commentsList) {
        commentsList.innerHTML =
          '<div class="alert alert-danger">Error loading comments</div>';
      }
    }
  }

  async submit(event) {
    event.preventDefault();

    const formData = new FormData(event.target);
    const content = formData.get("comment[content]");

    if (!content.trim()) return;

    try {
      const response = await fetch(`/microposts/${this.micropostId}/comments`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        },
        body: JSON.stringify({ comment: { content: content } }),
      });

      const data = await response.json();

      if (data.success) {
        // Add comment to list
        this.addCommentToList(data.comment);

        // Update comment count
        const countElement = document.querySelector(
          `#micropost-${this.micropostId} .comments-count`
        );
        if (countElement) {
          countElement.dataset.count = data.comments_count;
          countElement.innerHTML = `<i class="far fa-comment"></i> ${data.comments_count}`;
        }

        // Clear form
        event.target.reset();
      }
    } catch (error) {
      console.error("Error posting comment:", error);
    }
  }

  async deleteComment(event) {
    event.preventDefault();

    if (!confirm("Are you sure you want to delete this comment?")) return;

    const commentId = event.currentTarget.dataset.commentId;

    try {
      const response = await fetch(
        `/microposts/${this.micropostId}/comments/${commentId}`,
        {
          method: "DELETE",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
              .content,
          },
        }
      );

      const data = await response.json();

      if (data.success) {
        // Remove comment from DOM
        document.querySelector(`#comment-${commentId}`).remove();

        // Update comment count
        const countElement = document.querySelector(
          `#micropost-${this.micropostId} .comments-count`
        );
        if (countElement) {
          countElement.dataset.count = data.comments_count;
          countElement.innerHTML = `<i class="far fa-comment"></i> ${data.comments_count}`;
        }
      }
    } catch (error) {
      console.error("Error deleting comment:", error);
    }
  }

  renderComments(comments) {
    const listElement = this.hasCommentsListTarget
      ? this.commentsListTarget
      : document.querySelector(`#comments-list-${this.micropostId}`);

    if (!listElement) return;

    listElement.innerHTML = comments
      .map((comment) => this.commentHTML(comment))
      .join("");
  }

  addCommentToList(comment) {
    const listElement = this.hasCommentsListTarget
      ? this.commentsListTarget
      : document.querySelector(`#comments-list-${this.micropostId}`);

    if (!listElement) return;

    listElement.insertAdjacentHTML("afterbegin", this.commentHTML(comment));
  }

  commentHTML(comment) {
    const deleteButton = comment.can_delete
      ? `<button class="btn btn-link btn-sm text-danger delete-comment-btn" data-comment-id="${comment.id}" data-action="click->comment#deleteComment">Delete</button>`
      : "";

    return `
      <div class="comment" id="comment-${comment.id}">
        <div class="comment-header">
          <strong>${comment.user.name}</strong>
          <small class="text-muted">${this.timeAgo(comment.created_at)}</small>
          ${deleteButton}
        </div>
        <div class="comment-content">${this.escapeHTML(comment.content)}</div>
      </div>
    `;
  }

  timeAgo(timestamp) {
    const seconds = Math.floor((new Date() - new Date(timestamp)) / 1000);

    const intervals = {
      year: 31536000,
      month: 2592000,
      week: 604800,
      day: 86400,
      hour: 3600,
      minute: 60,
    };

    for (const [unit, secondsInUnit] of Object.entries(intervals)) {
      const interval = Math.floor(seconds / secondsInUnit);
      if (interval >= 1) {
        return `${interval} ${unit}${interval === 1 ? "" : "s"} ago`;
      }
    }

    return "just now";
  }

  escapeHTML(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }
}
