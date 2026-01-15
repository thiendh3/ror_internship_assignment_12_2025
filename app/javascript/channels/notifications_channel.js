import consumer from "./consumer"

const notificationsChannel = consumer.subscriptions.create("NotificationsChannel", {
  connected() {
    console.log("Connected to notifications channel")
    this.updateBadge()
  },

  disconnected() {
    console.log("Disconnected from notifications channel")
  },

  received(data) {
    console.log("Received notification:", data)
    this.showNotification(data)
    this.updateBadge()
    this.addToNotificationsList(data)
  },

  showNotification(data) {
    const toast = document.createElement('div')
    toast.className = 'notification-toast alert alert-info'
    toast.style.cssText = 'position: fixed; top: 70px; right: 20px; z-index: 9999; min-width: 300px; cursor: pointer;'
    toast.innerHTML = `
      <strong>${data.actor?.name || 'Someone'}</strong>
      <br>${data.message}
      <button type="button" class="close" onclick="event.stopPropagation(); this.parentElement.remove()">&times;</button>
    `
    toast.addEventListener('click', () => {
      window.location.href = '/notifications'
    })
    document.body.appendChild(toast)

    setTimeout(() => toast.remove(), 5000)
  },

  addToNotificationsList(data) {
    const list = document.getElementById('notifications-list')
    if (!list) return

    // Only add to unread tab
    const url = new URL(window.location.href)
    if (url.searchParams.get('tab') === 'read') return

    const li = document.createElement('li')
    li.className = 'list-group-item'
    li.dataset.notificationId = data.id

    const actorLink = data.actor?.id ? `/notifications/${data.id}/mark_as_read` : '#'
    const actorName = data.actor?.name || 'Someone'

    li.innerHTML = `
      <div class="d-flex justify-content-between align-items-start">
        <div class="ms-2 me-auto">
          <a href="${actorLink}" data-method="post">
            <div class="fw-bold">${actorName}</div>
          </a>
          <span class="text-muted">${data.type === 'follow' ? 'started following you' : 'unfollowed you'}</span>
          <small class="text-muted d-block">just now</small>
        </div>
        <span class="badge bg-primary rounded-pill">New</span>
      </div>
    `
    list.insertBefore(li, list.firstChild)
  },

  updateBadge() {
    fetch('/notifications/unread_count')
      .then(response => response.json())
      .then(data => {
        const badge = document.getElementById('notification-badge')
        if (badge) {
          if (data.count > 0) {
            badge.textContent = data.count
            badge.style.display = 'inline'
          } else {
            badge.style.display = 'none'
          }
        }
      })
      .catch(err => console.error('Error updating badge:', err))
  }
})

document.addEventListener('turbo:load', () => {
  if (notificationsChannel) {
    notificationsChannel.updateBadge()
  }
})

export default notificationsChannel
