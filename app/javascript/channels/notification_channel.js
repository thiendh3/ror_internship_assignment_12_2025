import consumer from "channels/consumer";

consumer.subscriptions.create("NotificationChannel", {
	connected() {
		console.log("Connected to NotificationChannel");
	},

	received(data) {
		const badge = document.querySelector("#notification-count");
		if (badge) {
			const currentCount = parseInt(badge.innerText || 0);
			badge.innerText = currentCount + 1;
			badge.style.display = "inline-block";
		}

		const container = document.querySelector("#notifications-container");
		const noNotifMessage = document.querySelector("#no-notifications");

		if (noNotifMessage) noNotifMessage.remove();

		// Updated HTML to include avatar and matching structure
		const newNotificationHtml = `
        <li class="unread-notification">
            <a href="#" class="notification-item">
                <img src="${data.actor_avatar_url}" class="gravatar" style="width: 30px; height: 30px;">
                <div class="notification-content">
                    <span class="notification-text">
                        <strong>${data.actor_name}</strong> ${data.action} you
                    </span>
                    <span class="notification-time">${data.created_at}</span>
                </div>
            </a>
        </li>`;
		if (container) {
			container.insertAdjacentHTML("afterbegin", newNotificationHtml);
		}
	},
});

document.addEventListener("turbo:load", () => {
	const toggle = document.querySelector("#notification-toggle");

	if (toggle) {
		toggle.addEventListener("click", () => {
			const badge = document.querySelector("#notification-count");

			if (badge && badge.style.display !== "none") {
				badge.style.display = "none";
				badge.innerText = "0";

				fetch(toggle.dataset.url, {
					method: "POST",
					headers: {
						"X-CSRF-Token": document.querySelector(
							"[name='csrf-token']"
						).content,
						"Content-Type": "application/json",
					},
				}).catch((err) =>
					console.error("Notification request failed:", err)
				);
			}
		});
	}
});
