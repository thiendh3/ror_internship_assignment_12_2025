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
    
    console.log("Processing notification...")
    this.showNotification(data)
    console.log("Incrementing badge count...")
    this.incrementBadge()
    console.log("Calling updateTabBadge...")
    this.updateTabBadge()
    console.log("Calling addToNotificationsList...")
    this.addToNotificationsList(data)
    console.log("Calling updateMarkAllButton...")
    this.updateMarkAllButton()
    console.log("All updates complete!")
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
    // Check if we're on the notifications page
    const notificationsContainer = document.querySelector('.divide-y.divide-gray-200')
    if (!notificationsContainer) return

    const url = new URL(window.location.href)
    const currentTab = url.searchParams.get('tab') || 'all'
    if (currentTab === 'read') return

    const actorName = data.actor?.name || 'Deleted user'
    const actorAvatar = data.actor?.avatar_url || '/assets/default-avatar.png'
    const targetUrl = data.target_url || '#'

    // Create new notification element with new styling
    const notificationItem = document.createElement('a')
    notificationItem.href = `/notifications/${data.id}/mark_as_read`
    notificationItem.className = 'block notification-item hover:bg-gray-50 transition-colors bg-blue-50'
    notificationItem.dataset.notificationId = data.id
    notificationItem.dataset.method = 'post'
    
    notificationItem.innerHTML = `
      <div class="flex items-start gap-3 p-4">
        <img src="${actorAvatar}" class="w-14 h-14 rounded-full object-cover flex-shrink-0" alt="${actorName}">
        <div class="flex-1 min-w-0">
          <div class="text-sm">
            <span class="font-semibold text-gray-900">${actorName}</span>
            <span class="text-gray-700"> ${data.message}</span>
          </div>
          <div class="flex items-center gap-2 mt-1">
            <span class="text-xs text-blue-600">just now</span>
            <span class="w-2 h-2 bg-blue-600 rounded-full"></span>
          </div>
        </div>
      </div>
    `
    
    // Add click handler
    notificationItem.addEventListener('click', async (e) => {
      e.preventDefault()
      // Mark as read first
      await fetch(`/notifications/${data.id}/mark_as_read`, { 
        method: 'POST',
        headers: { 
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })
      // Then navigate to target
      if (targetUrl && targetUrl !== '#') {
        window.location.href = targetUrl
      }
    })
    
    // Insert at the beginning
    notificationsContainer.insertBefore(notificationItem, notificationsContainer.firstChild)
    
    // Update unread count in tab badge
    this.updateTabBadge()
  },

  updateTabBadge() {
    fetch('/notifications/unread_count')
      .then(response => response.json())
      .then(data => {
        console.log('Updating tab badge with count:', data.count)
        // Update badge in header
        const headerBadge = document.getElementById('notification-badge')
        if (headerBadge) {
          if (data.count > 0) {
            headerBadge.textContent = data.count > 9 ? '9+' : data.count
            headerBadge.classList.remove('hidden')
          } else {
            headerBadge.classList.add('hidden')
          }
        }
        
        // Update badge in "Unread" tab
        const tabBadgeContainer = document.querySelector('a[href*="tab=unread"] .bg-red-500.rounded-full')
        if (tabBadgeContainer) {
          if (data.count > 0) {
            tabBadgeContainer.textContent = data.count
            tabBadgeContainer.classList.remove('hidden')
          } else {
            tabBadgeContainer.classList.add('hidden')
          }
        }
      })
      .catch(err => console.error('Error updating tab badge:', err))
  },

  updateMarkAllButton() {
    fetch('/notifications/unread_count')
      .then(response => response.json())
      .then(data => {
        const markAllSection = document.querySelector('.flex.items-center.justify-between.px-4.py-3.bg-gray-50')
        
        if (data.count > 0) {
          // If section doesn't exist, we might need to reload or show it
          if (markAllSection) {
            // Update the count text
            const countText = markAllSection.querySelector('.text-sm.text-gray-600')
            if (countText) {
              const plural = data.count === 1 ? 'unread notification' : 'unread notifications'
              countText.textContent = `${data.count} ${plural}`
            }
          } else {
            // Section doesn't exist, might need to show it
            // For now, we can live with it showing after refresh
          }
        } else {
          // Hide the mark all section if no unread
          if (markAllSection) {
            markAllSection.style.display = 'none'
          }
        }
      })
      .catch(err => console.error('Error updating mark all button:', err))
  },

  // Increment badge count by 1 (for real-time updates)
  incrementBadge() {
    const badge = document.getElementById('notification-badge')
    if (badge) {
      // Get current count
      let currentCount = parseInt(badge.textContent) || 0
      if (badge.textContent === '9+') {
        currentCount = 10 // If it's already 9+, keep it at 9+
      }
      
      // Increment
      const newCount = currentCount + 1
      const displayCount = newCount > 9 ? '9+' : String(newCount)
      
      badge.textContent = displayCount
      badge.classList.remove('hidden')
      
      console.log('Badge incremented to:', displayCount)
    }
  },

  // Fetch and update badge count from server (for page load)
  updateBadge() {
    fetch('/notifications/unread_count')
      .then(response => response.json())
      .then(data => {
        console.log('Updating badge with count:', data.count)
        // Update badge in header
        const badge = document.getElementById('notification-badge')
        if (badge) {
          // Set content first - ensure it's a string
          const displayCount = data.count > 9 ? '9+' : String(data.count)
          badge.textContent = displayCount
          
          // Then show/hide using only class (don't set inline style)
          if (data.count > 0) {
            badge.classList.remove('hidden')
          } else {
            badge.classList.add('hidden')
          }
          console.log('Badge updated successfully to:', displayCount)
        } else {
          console.error('Badge element not found!')
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
