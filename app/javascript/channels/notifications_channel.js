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
    
    // Extra safety check: skip if actor is current user
    const currentUserId = document.body.dataset.currentUserId
    if (currentUserId && data.actor && parseInt(currentUserId) === data.actor.id) {
      console.log("Skipping notification from self")
      return
    }
    
    this.showNotification(data)
    this.updateBadge()
    this.addToNotificationsList(data)
  },

  showNotification(data) {
    const toast = document.createElement('div')
    toast.className = 'notification-toast alert alert-info'
    toast.style.cssText = 'position: fixed; top: 70px; right: 20px; z-index: 9999; min-width: 300px; cursor: pointer; box-shadow: 0 4px 12px rgba(0,0,0,0.15);'
    
    const actorName = data.actor?.name || 'Someone'
    const targetUrl = data.target_url || '/notifications'
    
    toast.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: start;">
        <div>
          <strong>${actorName}</strong> ${data.message}
        </div>
        <button type="button" class="close" style="background: none; border: none; font-size: 20px; cursor: pointer;" onclick="event.stopPropagation(); this.closest('.notification-toast').remove()">&times;</button>
      </div>
    `
    toast.addEventListener('click', () => {
      window.location.href = targetUrl
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
    li.className = 'list-group-item notification-item unread'
    li.dataset.notificationId = data.id
    li.style.cursor = 'pointer'

    const actorName = data.actor?.name || 'Someone'
    const targetUrl = data.target_url || '/notifications'

    li.innerHTML = `
      <div class="d-flex justify-content-between align-items-start">
        <div class="ms-2 me-auto">
          <div class="fw-bold">${actorName}</div>
          <span class="text-muted">${data.message}</span>
          <small class="text-muted d-block">just now</small>
        </div>
        <span class="badge bg-primary rounded-pill">New</span>
      </div>
    `
    
    li.addEventListener('click', async () => {
      // Mark as read first
      await fetch(`/notifications/${data.id}/mark_as_read`, { 
        method: 'POST',
        headers: { 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content }
      })
      // Then navigate to target
      window.location.href = targetUrl
    })
    
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
