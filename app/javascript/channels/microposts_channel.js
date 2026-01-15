import consumer from "./consumer"

const micropostsChannel = consumer.subscriptions.create(
  { channel: "MicropostsChannel" },
  {
    connected() {
      console.log("Connected to microposts channel")
    },

    disconnected() {
      console.log("Disconnected from microposts channel")
    },

    received(data) {
      console.log("Received micropost update:", data)
      
      switch(data.action) {
        case 'create':
          this.handleCreate(data)
          break
        case 'update':
          this.handleUpdate(data)
          break
        case 'destroy':
          this.handleDestroy(data)
          break
      }
    },

    handleCreate(data) {
      const feedList = document.getElementById('feed-items')
      if (!feedList) return

      // Don't add if it's current user's own post (already added via AJAX)
      const currentUserId = document.body.dataset.currentUserId
      if (currentUserId && parseInt(currentUserId) === data.user_id) return

      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = data.html
      const newItem = tempDiv.firstElementChild

      if (newItem) {
        newItem.style.opacity = '0'
        feedList.insertBefore(newItem, feedList.firstChild)
        
        // Init click handlers for new item
        if (window.MicropostActions) {
          window.MicropostActions.initMicropostActions()
        }
        
        // Fade in animation
        requestAnimationFrame(() => {
          newItem.style.transition = 'opacity 0.3s ease-in'
          newItem.style.opacity = '1'
        })
      }
    },

    handleUpdate(data) {
      const micropostEl = document.getElementById(`micropost-${data.micropost_id}`)
      if (!micropostEl) return

      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = data.html
      const newItem = tempDiv.firstElementChild

      if (newItem) {
        micropostEl.replaceWith(newItem)
        
        // Init click handlers for updated item
        if (window.MicropostActions) {
          window.MicropostActions.initMicropostActions()
        }
        
        // Flash effect
        newItem.style.backgroundColor = '#ffffd0'
        setTimeout(() => {
          newItem.style.transition = 'background-color 0.5s ease'
          newItem.style.backgroundColor = ''
        }, 100)
      }
    },

    handleDestroy(data) {
      const micropostEl = document.getElementById(`micropost-${data.micropost_id}`)
      if (!micropostEl) return

      micropostEl.style.transition = 'opacity 0.3s ease-out'
      micropostEl.style.opacity = '0'
      setTimeout(() => micropostEl.remove(), 300)
    }
  }
)

export default micropostsChannel
