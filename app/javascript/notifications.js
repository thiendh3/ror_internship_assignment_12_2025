// Notifications functionality
let notificationsPollStarted = false;
let notificationsDocBound = false;

function initializeNotifications() {
    const bell = document.querySelector('.notifications-bell');
    if (!bell) return;

    if (!notificationsPollStarted) {
        notificationsPollStarted = true;
        updateNotificationCount();
        // Poll for new notifications every 30 seconds
        setInterval(updateNotificationCount, 30000);
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

function updateNotificationCount() {
    fetch('/notifications/unread_count', {
        headers: {
            'Accept': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
    })
        .then(resp => resp.json())
        .then(data => {
            const badge = document.querySelector('.notification-badge');
            if (badge) {
                if (data.unread_count > 0) {
                    badge.textContent = data.unread_count > 99 ? '99+' : data.unread_count;
                    badge.style.display = 'inline-block';
                } else {
                    badge.style.display = 'none';
                }
            }
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

    container.innerHTML = notifications.map(notif => `
        <div class="notification-item ${notif.read ? 'read' : 'unread'}" 
             data-notification-id="${notif.id}"
             data-micropost-id="${notif.notifiable?.id}">
            <img src="${notif.actor.gravatar_url}" alt="${notif.actor.name}" class="notification-avatar">
            <div class="notification-content">
                <div class="notification-message">
                    <strong>${notif.actor.name}</strong> liked your post
                </div>
                <div class="notification-preview">${truncate(notif.notifiable?.content, 50)}</div>
                <div class="notification-time">${timeAgo(notif.created_at)}</div>
            </div>
        </div>
    `).join('');

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
