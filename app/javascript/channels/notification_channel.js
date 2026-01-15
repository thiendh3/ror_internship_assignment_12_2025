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

		// Render new notification with actor avatar and unread styling
		const newNotificationHtml = `
            <li class="unread-notification">
                <a href="${data.actor_url}" class="notification-item">
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
	const $toggle = $("#notification-toggle");
	const $dropdownParent = $toggle.closest(".dropdown");
	const listContainer = document.querySelector("#notification-list");
	const csrfToken = document.querySelector("[name='csrf-token']").content;

	if ($toggle.length) {
		// 1. Remove the red notification count badge immediately on OPEN
		$toggle.on("click", () => {
			const badge = document.querySelector("#notification-count");
			if (badge && badge.style.display !== "none") {
				badge.style.display = "none";
				badge.innerText = "0";
			}
		});

		// 2. Clear internal "new" indicators and update server only on CLOSE
		$dropdownParent.on("hidden.bs.dropdown", () => {
			const internalBadge = document.querySelector(".unread-count-label");
			const unreadItems = document.querySelectorAll(
				".unread-notification"
			);

			// Only execute if there are unread notifications to clear
			if (internalBadge || unreadItems.length > 0) {
				if (internalBadge) internalBadge.remove();
				unreadItems.forEach((item) =>
					item.classList.remove("unread-notification")
				);

				// POST request to mark all as read with security headers
				fetch($toggle.data("url"), {
					method: "POST",
					headers: {
						"X-CSRF-Token": csrfToken,
						"Content-Type": "application/json",
						"X-Requested-With": "XMLHttpRequest", // Prevents 422 security error
					},
				}).catch((err) =>
					console.error("Notification request failed:", err)
				);
			}
		});
	}

	// 3. Infinite Scroll Logic
	if (listContainer) {
		listContainer.addEventListener("scroll", () => {
			const container = document.querySelector(
				"#notifications-container"
			);
			const { scrollTop, scrollHeight, clientHeight } = listContainer;
			const nextPage = container.dataset.nextPage;
			const totalPages = container.dataset.totalPages;

			// Trigger fetch if user scrolls to the bottom and more pages exist
			if (
				scrollTop + clientHeight >= scrollHeight - 10 &&
				nextPage &&
				nextPage !== "null" &&
				parseInt(nextPage) <= parseInt(totalPages) &&
				!listContainer.dataset.loading
			) {
				listContainer.dataset.loading = "true";

				fetch(`/notifications?page=${nextPage}`, {
					headers: {
						Accept: "text/javascript",
						"X-Requested-With": "XMLHttpRequest",
						"X-CSRF-Token": csrfToken,
					},
				})
					.then((res) => (res.ok ? res.text() : Promise.reject()))
					.then((code) => {
						// Execute the JavaScript returned by the Rails controller
						const script = document.createElement("script");
						script.text = code;
						document.head
							.appendChild(script)
							.parentNode.removeChild(script);
					})
					.catch((err) =>
						console.error("Infinite scroll failed:", err)
					)
					.finally(() => delete listContainer.dataset.loading);
			}
		});
	}
});
