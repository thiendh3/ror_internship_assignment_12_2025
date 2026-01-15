// AJAX handlers for Microposts

document.addEventListener('DOMContentLoaded', () => {
  cleanupMicropostModals()
  initMicropostForm()
  initMicropostActions()
})

document.addEventListener('turbo:load', () => {
  cleanupMicropostModals()
  initMicropostForm()
  initMicropostActions()
})

document.addEventListener('turbo:before-visit', () => {
  cleanupMicropostModals()
})

function cleanupMicropostModals() {
  const modal = document.getElementById('micropost-modal')
  const backdrop = document.getElementById('micropost-modal-backdrop')
  if (modal) modal.remove()
  if (backdrop) backdrop.remove()
  document.body.style.overflow = ''
}

function initMicropostForm() {
  const form = document.getElementById('micropost-form')
  const submitBtn = document.getElementById('micropost-submit-btn')
  if (!form || !submitBtn || submitBtn.dataset.ajaxInitialized) return
  
  submitBtn.dataset.ajaxInitialized = 'true'
  
  submitBtn.addEventListener('click', async (e) => {
    e.preventDefault()
    e.stopPropagation()
    
    const originalText = submitBtn.textContent
    submitBtn.textContent = 'Posting...'
    submitBtn.disabled = true
    
    try {
      const formData = new FormData(form)
      const response = await fetch('/microposts.json', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        // Add to feed
        const feedList = document.getElementById('feed-items')
        if (feedList && data.html) {
          const tempDiv = document.createElement('div')
          tempDiv.innerHTML = data.html
          const newItem = tempDiv.firstElementChild
          
          if (newItem) {
            newItem.style.opacity = '0'
            feedList.insertBefore(newItem, feedList.firstChild)
            initMicropostActions()
            
            requestAnimationFrame(() => {
              newItem.style.transition = 'opacity 0.3s ease-in'
              newItem.style.opacity = '1'
            })
          }
        }
        
        // Clear form and reset visibility to public
        form.reset()
        const visibilitySelect = document.getElementById('micropost_visibility')
        if (visibilitySelect) visibilitySelect.value = 'public'
        showFlash('success', 'Micropost created!')
      } else {
        showFlash('danger', data.errors.join(', '))
      }
    } catch (error) {
      console.error('Error creating micropost:', error)
      showFlash('danger', 'Failed to create micropost')
    } finally {
      submitBtn.textContent = originalText
      submitBtn.disabled = false
    }
  })
}

function initMicropostActions() {
  // Delete buttons
  document.querySelectorAll('.micropost-delete:not([data-ajax-initialized])').forEach(btn => {
    btn.dataset.ajaxInitialized = 'true'
    btn.addEventListener('click', async (e) => {
      e.preventDefault()
      
      if (!confirm('Are you sure you want to delete this micropost?')) return
      
      const micropostId = btn.dataset.micropostId
      const micropostEl = document.getElementById(`micropost-${micropostId}`)
      
      try {
        const response = await fetch(`/microposts/${micropostId}`, {
          method: 'DELETE',
          headers: {
            'Accept': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          }
        })
        
        const data = await response.json()
        
        if (data.success) {
          micropostEl.style.transition = 'opacity 0.3s ease-out'
          micropostEl.style.opacity = '0'
          setTimeout(() => micropostEl.remove(), 300)
          showFlash('success', 'Micropost deleted!')
        } else {
          showFlash('danger', 'Failed to delete micropost')
        }
      } catch (error) {
        console.error('Error deleting micropost:', error)
        showFlash('danger', 'Failed to delete micropost')
      }
    })
  })
  
  // Edit buttons
  document.querySelectorAll('.micropost-edit:not([data-ajax-initialized])').forEach(btn => {
    btn.dataset.ajaxInitialized = 'true'
    btn.addEventListener('click', (e) => {
      e.preventDefault()
      e.stopPropagation()
      const micropostId = btn.dataset.micropostId
      const isShared = btn.dataset.isShared === 'true'
      enableInlineEdit(micropostId, isShared)
    })
  })

  // Visibility toggle buttons
  document.querySelectorAll('.visibility-toggle:not([data-ajax-initialized])').forEach(btn => {
    btn.dataset.ajaxInitialized = 'true'
    btn.addEventListener('click', async (e) => {
      e.preventDefault()
      e.stopPropagation()
      const micropostId = btn.dataset.micropostId
      const currentVisibility = btn.textContent.trim() === '🌍' ? 'public' : 'private'
      const newVisibility = currentVisibility === 'public' ? 'private' : 'public'

      try {
        const response = await fetch(`/microposts/${micropostId}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ micropost: { visibility: newVisibility } })
        })

        const data = await response.json()
        if (data.success) {
          // Update button icon
          btn.textContent = newVisibility === 'public' ? '🌍' : '🔒'
          // Update badge in header
          const micropostEl = document.getElementById(`micropost-${micropostId}`)
          const badge = micropostEl.querySelector('.visibility-badge')
          if (newVisibility === 'private') {
            if (!badge) {
              const timestamp = micropostEl.querySelector('.timestamp')
              if (timestamp) {
                const newBadge = document.createElement('span')
                newBadge.className = 'visibility-badge ms-2'
                newBadge.title = 'Only you can see this'
                newBadge.textContent = '🔒'
                timestamp.appendChild(newBadge)
              }
            }
          } else {
            if (badge) badge.remove()
          }
          showFlash('success', `Post is now ${newVisibility}`)
        } else {
          showFlash('danger', 'Failed to update visibility')
        }
      } catch (error) {
        console.error('Error updating visibility:', error)
        showFlash('danger', 'Failed to update visibility')
      }
    })
  })
  
  // Clickable micropost items (open modal)
  const clickableItems = document.querySelectorAll('.micropost-clickable:not([data-ajax-initialized])')
  console.log('Found clickable items:', clickableItems.length)
  clickableItems.forEach(item => {
    item.dataset.ajaxInitialized = 'true'
    item.addEventListener('click', async (e) => {
      console.log('Micropost clicked:', item.dataset.micropostId)
      // Don't open modal if clicking on links or buttons
      if (e.target.closest('a') || e.target.closest('button') || e.target.closest('.micropost-actions')) {
        console.log('Click ignored - on link/button')
        return
      }
      e.preventDefault()
      const micropostId = item.dataset.micropostId
      console.log('Opening modal for:', micropostId)
      await showMicropostModal(micropostId)
    })
  })
}

function createShareCaptionElement(micropostEl) {
  // Create caption div if it doesn't exist
  const captionDiv = document.createElement('div')
  captionDiv.className = 'share-caption'
  
  // Insert after micropost-header
  const header = micropostEl.querySelector('.micropost-header')
  if (header) {
    header.after(captionDiv)
  }
  
  return captionDiv
}

function enableInlineEdit(micropostId, isShared = false) {
  const micropostEl = document.getElementById(`micropost-${micropostId}`)
  if (!micropostEl) return

  // For shared posts, edit the caption; for regular posts, edit the content
  const contentEl = isShared 
    ? micropostEl.querySelector('.share-caption') || createShareCaptionElement(micropostEl)
    : micropostEl.querySelector('.content')
  
  const currentContent = contentEl.textContent.trim()

  // Store original HTML
  contentEl.dataset.originalHtml = contentEl.innerHTML

  // Get current visibility from edit button
  const editBtn = micropostEl.querySelector('.micropost-edit')
  const currentVisibility = editBtn?.dataset.visibility || 'public'

  // Create edit form
  contentEl.innerHTML = `
    <form class="inline-edit-form" data-micropost-id="${micropostId}">
      <textarea class="form-control mb-2" rows="2" placeholder="${isShared ? 'Add a caption...' : 'Edit content...'}">${currentContent}</textarea>
      <div class="d-flex align-items-center gap-2">
        <select class="form-select form-select-sm visibility-select" style="width: auto;">
          <option value="public" ${currentVisibility === 'public' ? 'selected' : ''}>🌍 Public</option>
          <option value="private" ${currentVisibility === 'private' ? 'selected' : ''}>🔒 Private</option>
        </select>
        <div class="btn-group btn-group-sm">
          <button type="submit" class="btn btn-primary btn-sm">Save</button>
          <button type="button" class="btn btn-secondary btn-sm cancel-edit">Cancel</button>
        </div>
      </div>
    </form>
  `

  const form = contentEl.querySelector('.inline-edit-form')
  const textarea = form.querySelector('textarea')
  textarea.focus()

  // Prevent clicks inside form from triggering modal
  form.addEventListener('click', (e) => e.stopPropagation())

  // Cancel button
  form.querySelector('.cancel-edit').addEventListener('click', () => {
    contentEl.innerHTML = contentEl.dataset.originalHtml
    // Remove caption element if it was empty
    if (isShared && !currentContent) {
      contentEl.remove()
    }
  })

  // Submit form
  form.addEventListener('submit', async (e) => {
    e.preventDefault()
    const newContent = textarea.value.trim()

    // Allow empty content for shared posts (caption is optional)
    if (!newContent && !isShared) {
      showFlash('danger', 'Content cannot be empty')
      return
    }

    try {
      const newVisibility = form.querySelector('.visibility-select').value
      const response = await fetch(`/microposts/${micropostId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ micropost: { content: newContent, visibility: newVisibility } })
      })

      const data = await response.json()

      if (data.success) {
        // Replace with updated HTML
        if (data.html) {
          const tempDiv = document.createElement('div')
          tempDiv.innerHTML = data.html
          const newItem = tempDiv.firstElementChild
          micropostEl.replaceWith(newItem)
          initMicropostActions()
          if (window.SocialFeatures) {
            window.SocialFeatures.initSocialFeatures()
          }
          
          // Flash effect
          newItem.style.backgroundColor = '#d4edda'
          setTimeout(() => {
            newItem.style.transition = 'background-color 0.5s ease'
            newItem.style.backgroundColor = ''
          }, 100)
        }
        showFlash('success', 'Micropost updated!')
      } else {
        showFlash('danger', data.errors.join(', '))
      }
    } catch (error) {
      console.error('Error updating micropost:', error)
      showFlash('danger', 'Failed to update micropost')
    }
  })
}

async function showMicropostModal(micropostId) {
  // Remove existing modal and backdrop first
  const existingModal = document.getElementById('micropost-modal')
  const existingBackdrop = document.getElementById('micropost-modal-backdrop')
  if (existingModal) existingModal.remove()
  if (existingBackdrop) existingBackdrop.remove()
  document.body.classList.remove('modal-open')

  try {
    const response = await fetch(`/microposts/${micropostId}`, {
      headers: {
        'Accept': 'application/json'
      }
    })
    
    if (!response.ok) {
      throw new Error('Failed to fetch micropost')
    }
    
    const data = await response.json()
    
    // Create backdrop first
    const backdrop = document.createElement('div')
    backdrop.id = 'micropost-modal-backdrop'
    backdrop.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1040;'
    document.body.appendChild(backdrop)
    
    // Build versions HTML
    let versionsHtml = ''
    if (data.versions && data.versions.length > 0) {
      versionsHtml = `
        <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #ddd;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
            <span style="font-weight: bold; font-size: 14px; color: #65676b;">📝 Edit History (${data.versions.length})</span>
            <button id="toggle-versions-btn" style="background: #e4e6eb; border: none; border-radius: 4px; padding: 4px 8px; cursor: pointer; font-size: 12px;">Show</button>
          </div>
          <div id="versions-list" style="display: none;">
            ${data.versions.map((v, i) => `
              <div style="padding: 8px; margin-bottom: 8px; background: #f0f2f5; border-radius: 8px;">
                <div style="font-size: 12px; color: #65676b; margin-bottom: 4px;">Version ${data.versions.length - i} • ${v.time_ago} ago</div>
                <div style="font-size: 14px; white-space: pre-wrap;">${v.content}</div>
              </div>
            `).join('')}
          </div>
        </div>
      `
    }

    // Create modal
    const modal = document.createElement('div')
    modal.id = 'micropost-modal'
    modal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: 1050; display: flex; align-items: center; justify-content: center;'
    modal.innerHTML = `
      <div style="background: white; border-radius: 8px; max-width: 600px; width: 90%; max-height: 80vh; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
        <div style="padding: 12px 16px; border-bottom: 1px solid #ddd; display: flex; justify-content: space-between; align-items: center;">
          <h5 style="margin: 0; font-weight: bold; font-size: 18px;">${data.user.name}'s post ${data.edited ? '<span style="font-size: 12px; color: #65676b;">(edited)</span>' : ''}</h5>
          <button id="modal-close-btn" style="background: #e4e6eb; border: none; border-radius: 50%; width: 36px; height: 36px; cursor: pointer; font-size: 20px;">&times;</button>
        </div>
        <div style="padding: 16px; max-height: 60vh; overflow-y: auto;">
          <div style="display: flex; align-items: center; margin-bottom: 12px;">
            <img src="${data.user.gravatar_url}" style="width: 40px; height: 40px; border-radius: 50%; margin-right: 10px;">
            <div>
              <a href="/users/${data.user.id}" style="font-weight: bold; text-decoration: none; color: #333;">${data.user.name}</a>
              <div style="font-size: 13px; color: #65676b;">${data.time_ago} ago</div>
            </div>
          </div>
          <p style="font-size: 15px; margin-bottom: 12px; white-space: pre-wrap;">${data.content}</p>
          ${data.image_url ? `<img src="${data.image_url}" style="max-width: 100%; border-radius: 8px;">` : ''}
          ${versionsHtml}
        </div>
        <div style="padding: 12px; border-top: 1px solid #ddd; display: flex; gap: 8px;">
          <a href="/users/${data.user.id}" style="flex: 1; text-align: center; padding: 8px; background: #e4e6eb; border-radius: 4px; text-decoration: none; color: #333;">View Profile</a>
          <button id="modal-close-btn-2" style="flex: 1; padding: 8px; background: #e4e6eb; border: none; border-radius: 4px; cursor: pointer;">Close</button>
        </div>
      </div>
    `
    
    document.body.appendChild(modal)
    document.body.style.overflow = 'hidden'
    
    // Close function
    const closeModal = () => {
      modal.remove()
      backdrop.remove()
      document.body.style.overflow = ''
    }
    
    // Close on button click
    document.getElementById('modal-close-btn').addEventListener('click', closeModal)
    document.getElementById('modal-close-btn-2').addEventListener('click', closeModal)
    
    // Toggle versions list
    const toggleBtn = document.getElementById('toggle-versions-btn')
    const versionsList = document.getElementById('versions-list')
    if (toggleBtn && versionsList) {
      toggleBtn.addEventListener('click', () => {
        if (versionsList.style.display === 'none') {
          versionsList.style.display = 'block'
          toggleBtn.textContent = 'Hide'
        } else {
          versionsList.style.display = 'none'
          toggleBtn.textContent = 'Show'
        }
      })
    }
    
    // Close on backdrop click
    backdrop.addEventListener('click', closeModal)
    
    // Close on clicking outside modal content
    modal.addEventListener('click', (e) => {
      if (e.target === modal) closeModal()
    })
    
    // Close on ESC key
    const escHandler = (e) => {
      if (e.key === 'Escape') {
        closeModal()
        document.removeEventListener('keydown', escHandler)
      }
    }
    document.addEventListener('keydown', escHandler)
  } catch (error) {
    console.error('Error fetching micropost:', error)
    showFlash('danger', 'Failed to load micropost')
  }
}

function showFlash(type, message) {
  // Remove existing flash
  const existingFlash = document.querySelector('.ajax-flash')
  if (existingFlash) existingFlash.remove()
  
  const flash = document.createElement('div')
  flash.className = `ajax-flash alert alert-${type} alert-dismissible fade show`
  flash.style.cssText = 'position: fixed; top: 70px; right: 20px; z-index: 9999; min-width: 300px;'
  flash.innerHTML = `
    ${message}
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  `
  
  document.body.appendChild(flash)
  
  // Auto-dismiss
  setTimeout(() => {
    flash.style.transition = 'opacity 0.3s ease'
    flash.style.opacity = '0'
    setTimeout(() => flash.remove(), 300)
  }, 4000)
  
  // Manual dismiss
  flash.querySelector('.btn-close').addEventListener('click', () => flash.remove())
}

// Export for use in other modules
window.MicropostActions = {
  initMicropostForm,
  initMicropostActions,
  enableInlineEdit,
  showMicropostModal,
  showFlash
}
