// AJAX handlers for Users

document.addEventListener('DOMContentLoaded', () => {
  cleanupModals()
  initUserFeatures()
})

document.addEventListener('turbo:load', () => {
  cleanupModals()
  initUserFeatures()
})

// Cleanup modals on page navigation
document.addEventListener('turbo:before-visit', () => {
  cleanupModals()
})

function cleanupModals() {
  // Remove user profile modal
  const userModal = document.getElementById('user-profile-modal')
  const userBackdrop = document.getElementById('user-profile-modal-backdrop')
  if (userModal) userModal.remove()
  if (userBackdrop) userBackdrop.remove()
  
  // Remove micropost modal
  const micropostModal = document.getElementById('micropost-modal')
  const micropostBackdrop = document.getElementById('micropost-modal-backdrop')
  if (micropostModal) micropostModal.remove()
  if (micropostBackdrop) micropostBackdrop.remove()
  
  // Reset body scroll
  document.body.style.overflow = ''
}

function initUserFeatures() {
  initAjaxPagination()
  initUserFilter()
  initUserProfileModal()
}

// ===== AJAX Pagination for Microposts =====
function initAjaxPagination() {
  const paginationContainer = document.querySelector('.ajax-pagination')
  if (!paginationContainer) return

  paginationContainer.addEventListener('click', async (e) => {
    const link = e.target.closest('a')
    if (!link) return
    
    e.preventDefault()
    const url = link.href
    
    try {
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      const data = await response.json()
      
      // Update microposts list
      const micropostsList = document.getElementById('user-microposts')
      if (micropostsList && data.html) {
        micropostsList.innerHTML = data.html
        initAjaxPagination()
        if (window.MicropostActions) {
          window.MicropostActions.initMicropostActions()
        }
      }
      
      // Update pagination
      const paginationEl = document.getElementById('microposts-pagination')
      if (paginationEl && data.pagination) {
        paginationEl.innerHTML = data.pagination
      }
      
      // Scroll to top of list
      micropostsList?.scrollIntoView({ behavior: 'smooth', block: 'start' })
    } catch (error) {
      console.error('Error loading page:', error)
    }
  })
}

// ===== User Filter (all, following, followers) =====
function initUserFilter() {
  const filterBtns = document.querySelectorAll('.user-filter-btn')
  if (!filterBtns.length) return

  filterBtns.forEach(btn => {
    if (btn.dataset.initialized) return
    btn.dataset.initialized = 'true'
    
    btn.addEventListener('click', async (e) => {
      e.preventDefault()
      
      // Update active state
      filterBtns.forEach(b => b.classList.remove('active'))
      btn.classList.add('active')
      
      const filter = btn.dataset.filter
      const userId = btn.dataset.userId
      
      try {
        const url = filter === 'all' 
          ? '/users' 
          : `/users/${userId}/${filter}`
        
        const response = await fetch(`${url}.json`, {
          headers: {
            'Accept': 'application/json'
          }
        })
        
        const data = await response.json()
        
        const usersList = document.getElementById('users-list')
        if (usersList && data.html) {
          usersList.innerHTML = data.html
        }
        
        // Update pagination if present
        const paginationEl = document.getElementById('users-pagination')
        if (paginationEl && data.pagination) {
          paginationEl.innerHTML = data.pagination
        }
      } catch (error) {
        console.error('Error filtering users:', error)
      }
    })
  })
}

// ===== User Profile Modal =====
function initUserProfileModal() {
  const userLinks = document.querySelectorAll('.user-profile-link')
  
  userLinks.forEach(link => {
    // Remove old listener by cloning
    const newLink = link.cloneNode(true)
    link.parentNode.replaceChild(newLink, link)
    
    newLink.addEventListener('click', async (e) => {
      // Allow ctrl/cmd click to open in new tab
      if (e.ctrlKey || e.metaKey) return
      
      e.preventDefault()
      e.stopPropagation()
      const userId = newLink.dataset.userId
      await showUserProfileModal(userId)
    })
  })
}

async function showUserProfileModal(userId) {
  // Remove existing modal
  const existingModal = document.getElementById('user-profile-modal')
  const existingBackdrop = document.getElementById('user-profile-modal-backdrop')
  if (existingModal) existingModal.remove()
  if (existingBackdrop) existingBackdrop.remove()

  try {
    const response = await fetch(`/users/${userId}.json`, {
      headers: {
        'Accept': 'application/json'
      }
    })
    
    if (!response.ok) throw new Error('Failed to fetch user')
    
    const data = await response.json()
    
    // Create backdrop
    const backdrop = document.createElement('div')
    backdrop.id = 'user-profile-modal-backdrop'
    backdrop.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1040;'
    document.body.appendChild(backdrop)
    
    // Create modal
    const modal = document.createElement('div')
    modal.id = 'user-profile-modal'
    modal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: 1050; display: flex; align-items: center; justify-content: center;'
    modal.innerHTML = `
      <div style="background: white; border-radius: 8px; max-width: 500px; width: 90%; max-height: 80vh; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.3);">
        <div style="padding: 12px 16px; border-bottom: 1px solid #ddd; display: flex; justify-content: space-between; align-items: center;">
          <h5 style="margin: 0; font-weight: bold; font-size: 18px;">User Profile</h5>
          <button id="user-modal-close-btn" style="background: #e4e6eb; border: none; border-radius: 50%; width: 36px; height: 36px; cursor: pointer; font-size: 20px;">&times;</button>
        </div>
        <div style="padding: 20px; text-align: center;">
          <img src="${data.gravatar_url}" style="width: 80px; height: 80px; border-radius: 50%; margin-bottom: 12px;">
          <h4 style="margin: 0 0 4px 0;">${data.name}</h4>
          <p style="color: #65676b; margin: 0 0 8px 0;">${data.email}</p>
          ${data.bio ? `<p style="margin: 0 0 16px 0;">${data.bio}</p>` : ''}
          
          <div style="display: flex; justify-content: center; gap: 24px; margin: 16px 0; padding: 12px; background: #f0f2f5; border-radius: 8px;">
            <div style="text-align: center;">
              <div style="font-weight: bold; font-size: 18px;">${data.microposts_count}</div>
              <div style="font-size: 12px; color: #65676b;">Microposts</div>
            </div>
            <div style="text-align: center;">
              <div style="font-weight: bold; font-size: 18px;">${data.following_count}</div>
              <div style="font-size: 12px; color: #65676b;">Following</div>
            </div>
            <div style="text-align: center;">
              <div style="font-weight: bold; font-size: 18px;">${data.followers_count}</div>
              <div style="font-size: 12px; color: #65676b;">Followers</div>
            </div>
          </div>
          
          ${data.follow_button_html || ''}
        </div>
        <div style="padding: 12px; border-top: 1px solid #ddd; display: flex; gap: 8px;">
          <a href="/users/${data.id}" style="flex: 1; text-align: center; padding: 8px; background: #0d6efd; color: white; border-radius: 4px; text-decoration: none;">View Full Profile</a>
          <button id="user-modal-close-btn-2" style="flex: 1; padding: 8px; background: #e4e6eb; border: none; border-radius: 4px; cursor: pointer;">Close</button>
        </div>
      </div>
    `
    
    document.body.appendChild(modal)
    document.body.style.overflow = 'hidden'
    
    // Close handlers
    const closeModal = () => {
      modal.remove()
      backdrop.remove()
      document.body.style.overflow = ''
    }
    
    document.getElementById('user-modal-close-btn').addEventListener('click', closeModal)
    document.getElementById('user-modal-close-btn-2').addEventListener('click', closeModal)
    backdrop.addEventListener('click', closeModal)
    modal.addEventListener('click', (e) => {
      if (e.target === modal) closeModal()
    })
    
    const escHandler = (e) => {
      if (e.key === 'Escape') {
        closeModal()
        document.removeEventListener('keydown', escHandler)
      }
    }
    document.addEventListener('keydown', escHandler)
    
    // Init follow button if present
    initFollowButtonInModal()
  } catch (error) {
    console.error('Error fetching user:', error)
  }
}

function initFollowButtonInModal() {
  const followBtn = document.querySelector('#user-profile-modal .follow-btn')
  if (!followBtn || followBtn.dataset.initialized) return
  
  followBtn.dataset.initialized = 'true'
  followBtn.addEventListener('click', async (e) => {
    e.preventDefault()
    
    const userId = followBtn.dataset.userId
    const isFollowing = followBtn.dataset.following === 'true'
    const url = isFollowing ? `/relationships/${followBtn.dataset.relationshipId}` : '/relationships'
    const method = isFollowing ? 'DELETE' : 'POST'
    
    try {
      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: !isFollowing ? JSON.stringify({ followed_id: userId }) : null
      })
      
      const data = await response.json()
      
      if (data.success) {
        // Toggle button state
        followBtn.dataset.following = (!isFollowing).toString()
        followBtn.textContent = isFollowing ? 'Follow' : 'Unfollow'
        followBtn.style.background = isFollowing ? '#0d6efd' : '#6c757d'
        
        if (data.relationship_id) {
          followBtn.dataset.relationshipId = data.relationship_id
        }
        
        // Update counts
        const followersCount = document.querySelector('#user-profile-modal .followers-count')
        if (followersCount) {
          const current = parseInt(followersCount.textContent)
          followersCount.textContent = isFollowing ? current - 1 : current + 1
        }
      }
    } catch (error) {
      console.error('Error following/unfollowing:', error)
    }
  })
}

// Export for use in other modules
window.UserActions = {
  initUserFeatures,
  initAjaxPagination,
  initUserFilter,
  initUserProfileModal,
  showUserProfileModal
}
