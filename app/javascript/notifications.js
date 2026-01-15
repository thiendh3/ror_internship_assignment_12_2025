// Notifications functionality
import consumer from "actioncable_consumer"

let notificationsPollStarted = false;
let notificationsDocBound = false;
let notificationSubscription = null;

function initializeNotifications() {
    const bell = document.querySelector('.notifications-bell');
    if (!bell) return;

    // Initialize WebSocket subscription once
    if (!notificationSubscription) {
        notificationSubscription = consumer.subscriptions.create("NotificationChannel", {
            connected() {
                console.log("Connected to NotificationChannel");
            },

            disconnected() {
                console.log("Disconnected from NotificationChannel");
            },

            received(data) {
                console.log("Received notification:", data);
                // Update badge count
                updateBadgeCount(data.unread_count);

                // Show toast notification (optional)
                showToastNotification(data);

                // Reload notifications if dropdown is open
                const dropdown = document.querySelector('.notifications-dropdown');
                if (dropdown && dropdown.classList.contains('show')) {
                    loadNotifications();
                }
            }
        });
    }

    // Keep polling as fallback (increase interval since we have WebSocket)
    if (!notificationsPollStarted) {
        notificationsPollStarted = true;
        updateNotificationCount();
        // Poll less frequently as fallback
        setInterval(updateNotificationCount, 60000);
    }

    if (!bell.dataset.notificationsBound) {
        bell.dataset.notificationsBound = 'true';
        bell.addEventListener('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            toggleNotificationsDropdown();
        });
    }

    if (!notificationsDocBound) {
        notificationsDocBound = true;
        // Click outside to close
        document.addEventListener('click', function (e) {
            const container = document.querySelector('.notifications-container');
            const dropdown = document.querySelector('.notifications-dropdown');

            if (!container || !dropdown) return;

            if (!container.contains(e.target)) {
                dropdown.classList.remove('show');
            }
        });
    }
}

function updateBadgeCount(count) {
    const badge = document.querySelector('.notification-badge');
    if (badge) {
        if (count > 0) {
            badge.textContent = count > 99 ? '99+' : count;
            badge.style.display = 'inline-block';
        } else {
            badge.style.display = 'none';
        }
    }
}

function showToastNotification(data) {
    // Optional: Show a brief toast/notification at top of page
    let message = '';
    if (data.type === 'like') {
        message = `<strong>${data.actor.name}</strong> liked your post`;
    } else if (data.type === 'comment') {
        message = `<strong>${data.actor.name}</strong> commented on your post`;
    } else if (data.type === 'mention') {
        message = `<strong>${data.actor.name}</strong> mentioned you`;
    }

    const toast = document.createElement('div');
    toast.className = 'notification-toast';
    toast.innerHTML = `
        <img src="${data.actor.gravatar_url}" alt="${data.actor.name}">
        <div>${message}</div>
    `;
    toast.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: white;
        border: 1px solid #ddd;
        border-radius: 4px;
        padding: 12px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        display: flex;
        gap: 10px;
        align-items: center;
        z-index: 10000;
        animation: slideIn 0.3s ease;
    `;

    document.body.appendChild(toast);

    setTimeout(() => {
        toast.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

function updateNotificationCount() {
    fetch('/notifications/unread_count', {
        headers: {
            'Accept': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
    })
        .then(resp => resp.json())
        .then(data => {
            updateBadgeCount(data.unread_count);
        })
        .catch(err => console.error('Error fetching notification count:', err));
}

function toggleNotificationsDropdown() {
    const dropdown = document.querySelector('.notifications-dropdown');
    if (!dropdown) return;

    const isVisible = dropdown.classList.contains('show');

    if (isVisible) {
        dropdown.classList.remove('show');
    } else {
        loadNotifications();
        dropdown.classList.add('show');
    }
}

function loadNotifications() {
    fetch('/notifications', {
        headers: {
            'Accept': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
    })
        .then(resp => resp.json())
        .then(data => {
            renderNotifications(data.notifications);
        })
        .catch(err => console.error('Error loading notifications:', err));
}

function renderNotifications(notifications) {
    const container = document.querySelector('.notifications-list');
    if (!container) return;

    if (notifications.length === 0) {
        container.innerHTML = '<div class="notification-item empty">No notifications</div>';
        return;
    }

    container.innerHTML = notifications.map(notif => {
        let message = '';
        if (notif.type === 'like') {
            message = `<strong>${notif.actor.name}</strong> liked your post`;
        } else if (notif.type === 'comment') {
            message = `<strong>${notif.actor.name}</strong> commented on your post`;
        } else if (notif.type === 'mention') {
            message = `<strong>${notif.actor.name}</strong> mentioned you`;
        }

        return `
            <div class="notification-item ${notif.read ? 'read' : 'unread'}" 
                 data-notification-id="${notif.id}"
                 data-micropost-id="${notif.notifiable?.id}">
                <img src="${notif.actor.gravatar_url}" alt="${notif.actor.name}" class="notification-avatar">
                <div class="notification-content">
                    <div class="notification-message">
                        ${message}
                    </div>
                    <div class="notification-preview">${truncate(notif.notifiable?.content, 50)}</div>
                    <div class="notification-time">${timeAgo(notif.created_at)}</div>
                </div>
            </div>
        `;
    }).join('');

    // Add click handlers
    container.querySelectorAll('.notification-item').forEach(item => {
        item.addEventListener('click', function () {
            const notifId = this.dataset.notificationId;
            const micropostId = this.dataset.micropostId;

            markNotificationAsRead(notifId);

            if (micropostId) {
                window.location.href = `/microposts/${micropostId}`;
            }
        });
    });
}

function markNotificationAsRead(notificationId) {
    fetch(`/notifications/${notificationId}/mark_as_read`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
    })
        .then(() => updateNotificationCount())
        .catch(err => console.error('Error marking notification as read:', err));
}

function truncate(str, length) {
    if (!str) return '';
    return str.length > length ? str.substring(0, length) + '...' : str;
}

function timeAgo(timestamp) {
    const now = new Date();
    const then = new Date(timestamp);
    const seconds = Math.floor((now - then) / 1000);

    if (seconds < 60) return 'just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`;
    return then.toLocaleDateString();
}

document.addEventListener('DOMContentLoaded', initializeNotifications);
document.addEventListener('turbo:load', initializeNotifications);
document.addEventListener('turbo:render', initializeNotifications);
