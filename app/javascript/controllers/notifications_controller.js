import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static targets = ["list", "badge", "dropdown"];

  connect() {
    this.consumer = createConsumer();
    this.subscription = this.consumer.subscriptions.create(
      { channel: "NotificationsChannel" },
      {
        received: (data) => this.handleNotification(data),
        connected: () => console.log("Notifications channel connected"),
        disconnected: () => console.log("Notifications channel disconnected"),
      }
    );

    this.loadNotifications();
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
    if (this.consumer) {
      this.consumer.disconnect();
    }
  }

  async loadNotifications() {
    try {
      const response = await fetch("/notifications", {
        headers: {
          Accept: "application/json",
        },
      });

      const data = await response.json();
      this.renderNotifications(data.notifications);
      this.updateBadge(data.unread_count);
    } catch (error) {
      console.error("Error loading notifications:", error);
    }
  }

  handleNotification(data) {
    // Add new notification to list
    if (this.hasListTarget) {
      this.prependNotification(data);
    }

    // Update badge
    const currentCount = parseInt(this.badgeTarget.textContent) || 0;
    this.updateBadge(currentCount + 1);

    // Show browser notification if permitted
    this.showBrowserNotification(data);
  }

  renderNotifications(notifications) {
    if (!this.hasListTarget) return;

    const header = `
      <li class="dropdown-header">
        Notifications
        <a class="pull-right" href="#" data-action="click->notifications#markAllAsRead" style="color: #337ab7; font-size: 12px; margin-left: 10px;">Mark all as read</a>
      </li>
      <li class="divider"></li>
    `;

    if (notifications.length === 0) {
      this.listTarget.innerHTML =
        header +
        '<li class="text-center text-muted" style="padding: 10px;">No notifications</li>';
      return;
    }

    this.listTarget.innerHTML =
      header +
      notifications
        .map((notification) => this.notificationHTML(notification))
        .join("");
  }

  prependNotification(notification) {
    if (!this.hasListTarget) return;

    // Find divider and insert after it
    const divider = this.listTarget.querySelector(".divider");
    if (divider) {
      divider.insertAdjacentHTML(
        "afterend",
        this.notificationHTML(notification)
      );
    }
  }

  notificationHTML(notification) {
    const readClass = notification.read ? "read" : "unread";
    const bgColor = notification.read ? "transparent" : "#f5f5f5";
    return `
      <li>
        <a href="#" class="notification-item ${readClass}" data-notification-id="${
      notification.id
    }" data-notification-url="${
      notification.url || "/"
    }" data-action="click->notifications#markAsReadAndNavigate" style="display: block; padding: 10px 20px; white-space: normal; background-color: ${bgColor};">
          <div style="margin-bottom: 5px;">
            <strong>${notification.actor.name}</strong>
            ${notification.message}
          </div>
          <small class="text-muted">${this.timeAgo(
            notification.created_at
          )}</small>
        </a>
      </li>
    `;
  }

  updateBadge(count) {
    if (!this.hasBadgeTarget) return;

    if (count > 0) {
      this.badgeTarget.textContent = count;
      this.badgeTarget.style.display = "inline";
    } else {
      this.badgeTarget.style.display = "none";
    }
  }

  async markAsReadAndNavigate(event) {
    event.preventDefault();

    const notificationId = event.currentTarget.dataset.notificationId;
    const notificationUrl = event.currentTarget.dataset.notificationUrl;

    if (!notificationId) return;

    try {
      // Mark as read
      const response = await fetch(
        `/notifications/${notificationId}/mark_as_read`,
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
              .content,
          },
        }
      );

      const data = await response.json();

      if (data.success) {
        // Update this notification item
        event.currentTarget.classList.remove("unread");
        event.currentTarget.classList.add("read");
        event.currentTarget.style.backgroundColor = "transparent";

        // Update badge
        this.updateBadge(data.unread_count);

        // Navigate to the URL
        if (notificationUrl && notificationUrl !== "/") {
          window.location.href = notificationUrl;
        }
      }
    } catch (error) {
      console.error("Error marking as read:", error);
    }
  }

  async markAllAsRead(event) {
    event.preventDefault();
    event.stopPropagation(); // Prevent dropdown from closing

    try {
      const response = await fetch("/notifications/mark_all_as_read", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
        },
      });

      const data = await response.json();

      if (data.success) {
        // Update all notification items
        this.listTarget
          .querySelectorAll(".notification-item")
          .forEach((item) => {
            item.classList.remove("unread");
            item.classList.add("read");
            item.style.backgroundColor = "transparent";
          });

        // Update badge
        this.updateBadge(0);
      }
    } catch (error) {
      console.error("Error marking all as read:", error);
    }
  }

  showBrowserNotification(data) {
    if (!("Notification" in window)) return;

    if (Notification.permission === "granted") {
      new Notification(data.message, {
        body: `From ${data.actor.name}`,
        icon: "/icon.png", // Add your icon path
      });
    } else if (Notification.permission !== "denied") {
      Notification.requestPermission().then((permission) => {
        if (permission === "granted") {
          new Notification(data.message);
        }
      });
    }
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
}
