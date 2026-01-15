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
        case 'reaction_update':
          this.handleReactionUpdate(data)
          break
        case 'comment_create':
          this.handleCommentCreate(data)
          break
        case 'comment_update':
          this.handleCommentUpdate(data)
          break
        case 'comment_destroy':
          this.handleCommentDestroy(data)
          break
        case 'share_create':
        case 'share_destroy':
          this.handleShareUpdate(data)
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
        if (window.SocialFeatures) {
          window.SocialFeatures.initSocialFeatures()
        }
        
        // Fade in animation
        requestAnimationFrame(() => {
          newItem.style.transition = 'opacity 0.3s ease-in'
          newItem.style.opacity = '1'
        })
      }
    },

    handleUpdate(data) {
      // Skip if current user updated (already handled via AJAX)
      const currentUserId = document.body.dataset.currentUserId
      if (currentUserId && parseInt(currentUserId) === data.user_id) return

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
        if (window.SocialFeatures) {
          window.SocialFeatures.initSocialFeatures()
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
      // Skip if current user deleted (already handled via AJAX)
      const currentUserId = document.body.dataset.currentUserId
      if (currentUserId && parseInt(currentUserId) === data.user_id) return

      const micropostEl = document.getElementById(`micropost-${data.micropost_id}`)
      if (!micropostEl) return

      micropostEl.style.transition = 'opacity 0.3s ease-out'
      micropostEl.style.opacity = '0'
      setTimeout(() => micropostEl.remove(), 300)
    },

    // Handle real-time reaction updates
    handleReactionUpdate(data) {
      // Skip if current user reacted (already handled via AJAX)
      const currentUserId = document.body.dataset.currentUserId
      if (currentUserId && parseInt(currentUserId) === data.user_id) return

      const reactionsData = data.reactions_data

      // Handle comment reactions
      if (data.reactable_type === 'comment') {
        this.handleCommentReactionUpdate(data.reactable_id, reactionsData)
        return
      }

      // Handle micropost reactions
      const micropostId = data.micropost_id
      const micropostEl = document.getElementById(`micropost-${micropostId}`)
      if (!micropostEl) return
      
      // Update reactions summary icons
      let iconsContainer = micropostEl.querySelector('.reactions-icons')
      const summaryEl = micropostEl.querySelector('.reactions-summary')
      
      // Create icons container if doesn't exist and we have reactions
      if (!iconsContainer && summaryEl && reactionsData.total_count > 0) {
        iconsContainer = document.createElement('div')
        iconsContainer.className = 'reactions-icons'
        summaryEl.insertBefore(iconsContainer, summaryEl.firstChild)
      }
      
      if (iconsContainer) {
        let html = ''
        if (reactionsData.top_reactions && reactionsData.top_reactions.length > 0) {
          reactionsData.top_reactions.forEach(rt => {
            html += `<span class="reaction-icon-small">${this.getReactionEmoji(rt)}</span>`
          })
        }
        if (reactionsData.total_count > 0) {
          html += `<span class="reactions-total">${reactionsData.total_count}</span>`
        }
        iconsContainer.innerHTML = html
        
        // Remove container if no reactions
        if (reactionsData.total_count === 0) {
          iconsContainer.remove()
        }
      }
      
      // Flash the reactions area to show update
      if (summaryEl) {
        summaryEl.style.backgroundColor = '#e8f4ff'
        setTimeout(() => {
          summaryEl.style.transition = 'background-color 0.5s ease'
          summaryEl.style.backgroundColor = ''
        }, 100)
      }
    },

    // Handle comment reaction updates
    handleCommentReactionUpdate(commentId, reactionsData) {
      const commentEl = document.querySelector(`[data-comment-id="${commentId}"]`)
      if (!commentEl) return

      // Update display
      let display = commentEl.querySelector('.comment-reactions-display')
      if (reactionsData.total_count > 0) {
        if (!display) {
          display = document.createElement('div')
          display.className = 'comment-reactions-display'
          const wrapper = commentEl.querySelector('.comment-reaction-wrapper')
          if (wrapper) wrapper.after(display)
        }
        let html = ''
        if (reactionsData.top_reactions) {
          reactionsData.top_reactions.forEach(rt => {
            html += `<span class="reaction-icon-tiny">${this.getReactionEmoji(rt)}</span>`
          })
        }
        html += `<span class="reaction-count">${reactionsData.total_count}</span>`
        display.innerHTML = html
      } else if (display) {
        display.remove()
      }

      // Flash effect
      const actions = commentEl.querySelector('.comment-actions')
      if (actions) {
        actions.style.backgroundColor = '#e8f4ff'
        setTimeout(() => {
          actions.style.transition = 'background-color 0.5s ease'
          actions.style.backgroundColor = ''
        }, 100)
      }
    },

    // Handle real-time comment creation
    handleCommentCreate(data) {
      const micropostId = data.micropost_id
      const micropostEl = document.getElementById(`micropost-${micropostId}`)
      if (!micropostEl) return

      // Skip if current user created this comment (already added via AJAX)
      const currentUserId = document.body.dataset.currentUserId
      if (currentUserId && parseInt(currentUserId) === data.user_id) return

      // Update comment count
      const commentStat = micropostEl.querySelector('.comments-stat')
      if (commentStat) {
        commentStat.textContent = `${data.total_count} comments`
      } else {
        const statsContainer = micropostEl.querySelector('.engagement-stats')
        if (statsContainer && data.total_count > 0) {
          statsContainer.insertAdjacentHTML('beforeend', `<span class="comments-stat">${data.total_count} comments</span>`)
        }
      }

      // If comments section is open, add the new comment (only for other users)
      const commentsContainer = micropostEl.querySelector('.comments-container')
      if (commentsContainer && commentsContainer.style.display !== 'none' && data.html) {
        const commentsList = commentsContainer.querySelector('.comments-list')
        // Check if comment already exists
        if (commentsList && !document.getElementById(`comment-${data.comment_id}`)) {
          commentsList.insertAdjacentHTML('beforeend', data.html)
        }
      }
    },

    // Handle real-time comment update
    handleCommentUpdate(data) {
      // Skip if current user updated (already handled via AJAX)
      const currentUserId = document.body.dataset.currentUserId
      if (currentUserId && parseInt(currentUserId) === data.user_id) return

      const commentEl = document.querySelector(`.comment-item[data-comment-id="${data.comment_id}"]`)
      if (!commentEl) return

      // Update comment text
      const commentTextEl = commentEl.querySelector('.comment-text')
      if (commentTextEl && data.comment) {
        commentTextEl.textContent = data.comment.content
        
        // Flash effect
        commentEl.style.backgroundColor = '#e8f4ff'
        setTimeout(() => {
          commentEl.style.transition = 'background-color 0.5s ease'
          commentEl.style.backgroundColor = ''
        }, 100)
      }
    },

    // Handle real-time comment deletion
    handleCommentDestroy(data) {
      // Skip if current user deleted (already handled via AJAX)
      const currentUserId = document.body.dataset.currentUserId
      if (currentUserId && parseInt(currentUserId) === data.user_id) return

      const micropostId = data.micropost_id
      const micropostEl = document.getElementById(`micropost-${micropostId}`)
      if (!micropostEl) return

      // Update comment count
      const commentStat = micropostEl.querySelector('.comments-stat')
      if (commentStat) {
        commentStat.textContent = data.total_count > 0 ? `${data.total_count} comments` : ''
      }

      // Remove the comment element if visible
      const commentEl = document.querySelector(`.comment-item[data-comment-id="${data.comment_id}"]`)
      if (commentEl) {
        commentEl.style.transition = 'opacity 0.3s ease-out'
        commentEl.style.opacity = '0'
        setTimeout(() => commentEl.remove(), 300)
      }
    },

    // Handle real-time share updates
    handleShareUpdate(data) {
      // Skip if current user shared (already handled via AJAX redirect)
      const currentUserId = document.body.dataset.currentUserId
      if (currentUserId && parseInt(currentUserId) === data.user_id) return

      const micropostId = data.micropost_id
      const micropostEl = document.getElementById(`micropost-${micropostId}`)
      if (!micropostEl) return

      // Update share count
      const shareStat = micropostEl.querySelector('.shares-stat')
      if (shareStat) {
        shareStat.textContent = data.shares_count > 0 ? `${data.shares_count} shares` : ''
      } else if (data.shares_count > 0) {
        const statsContainer = micropostEl.querySelector('.engagement-stats')
        if (statsContainer) {
          statsContainer.insertAdjacentHTML('beforeend', `<span class="shares-stat">${data.shares_count} shares</span>`)
        }
      }
    },

    getReactionEmoji(type) {
      const emojis = {
        'like': '👍',
        'love': '❤️',
        'haha': '😆',
        'wow': '😮',
        'sad': '😢',
        'angry': '😠'
      }
      return emojis[type] || '👍'
    }
  }
)

export default micropostsChannel
