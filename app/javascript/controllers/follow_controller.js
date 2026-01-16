import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "followersCount", "followingCount"];

  async toggle(event) {
    event.preventDefault();

    const link = event.currentTarget;
    const url = link.href;
    const method = link.dataset.method || "POST";

    // Get user id from the link or URL
    const userId = this.getUserId(link);

    try {
      const options = {
        method: method.toUpperCase(),
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          Accept: "application/json",
        },
      };

      // Add body for POST requests
      if (method.toUpperCase() === "POST") {
        options.body = JSON.stringify({ followed_id: userId });
      }

      const response = await fetch(url, options);
      const data = await response.json();

      if (data.success) {
        // Toggle button
        if (data.following) {
          // Change to Unfollow button
          link.textContent = "Unfollow";
          link.classList.remove("btn-primary");
          link.classList.add("btn-default");
          link.href = `/relationships/${data.relationship_id}`;
          link.dataset.method = "delete";
        } else {
          // Change to Follow button
          link.textContent = "Follow";
          link.classList.remove("btn-default");
          link.classList.add("btn-primary");
          link.href = "/relationships";
          link.dataset.method = "post";
        }

        // Update stats if available
        this.updateStats(data);
      }
    } catch (error) {
      console.error("Error toggling follow:", error);
    }
  }

  updateStats(data) {
    // Update followers count
    if (data.followers_count !== undefined) {
      const followersElement = document.getElementById("followers");
      if (followersElement) {
        followersElement.textContent = data.followers_count;
      }
    }

    // Update following count
    if (data.following_count !== undefined) {
      const followingElement = document.getElementById("following");
      if (followingElement) {
        followingElement.textContent = data.following_count;
      }
    }
  }

  getUserId(link) {
    // Try to get from href parameter first
    const urlParams = new URLSearchParams(link.href.split("?")[1]);
    if (urlParams.has("followed_id")) {
      return urlParams.get("followed_id");
    }

    // Otherwise get from the user profile link
    const userLink = link
      .closest(".user-item")
      ?.querySelector('.user-info a[href^="/users/"]');
    if (userLink) {
      return userLink.href.split("/").pop();
    }

    return null;
  }
}
