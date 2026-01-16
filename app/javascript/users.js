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
  initHeaderSearch()
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
    if (link.dataset.hoverInitialized) return
    link.dataset.hoverInitialized = 'true'
    
    let hoverTimeout
    let hideTimeout
    let currentModal = null
    
    // Show modal on hover
    link.addEventListener('mouseenter', async (e) => {
      clearTimeout(hideTimeout)
      
      hoverTimeout = setTimeout(async () => {
        const userId = link.dataset.userId
        if (userId) {
          currentModal = await showUserProfileModalOnHover(userId, link)
        }
      }, 500) // Delay 500ms before showing modal
    })
    
    // Hide modal when mouse leaves link
    link.addEventListener('mouseleave', (e) => {
      clearTimeout(hoverTimeout)
      
      // Check if mouse is moving to modal
      const relatedTarget = e.relatedTarget
      const modal = document.getElementById('user-profile-modal-hover')
      
      if (modal && (relatedTarget === modal || modal.contains(relatedTarget))) {
        // Mouse is moving to modal, don't hide
        return
      }
      
      // Delay hiding to allow moving to modal
      hideTimeout = setTimeout(() => {
        if (modal) {
          modal.remove()
          currentModal = null
        }
      }, 200)
    })
    
    // Keep click behavior to navigate to profile (don't prevent default)
  })
}

// Show modal on hover (positioned near the link)
async function showUserProfileModalOnHover(userId, triggerElement) {
  // Remove existing hover modal
  const existingModal = document.getElementById('user-profile-modal-hover')
  if (existingModal) existingModal.remove()

  try {
    const response = await fetch(`/users/${userId}.json`, {
      headers: {
        'Accept': 'application/json'
      }
    })
    
    if (!response.ok) throw new Error('Failed to fetch user')
    
    const data = await response.json()
    
    // Get trigger element position
    const rect = triggerElement.getBoundingClientRect()
    
    // Calculate position (below and aligned with trigger) - use fixed positioning
    let top = rect.bottom + 10
    let left = rect.left
    
    // Adjust if modal would go off screen
    const modalWidth = 320 // w-80 = 320px
    const modalHeight = 350 // Approximate height
    
    // Adjust horizontal position
    if (left + modalWidth > window.innerWidth) {
      left = window.innerWidth - modalWidth - 20
    }
    if (left < 20) {
      left = 20
    }
    
    // Adjust vertical position
    if (top + modalHeight > window.innerHeight) {
      top = rect.top - modalHeight - 10 // Show above instead
    }
    if (top < 20) {
      top = 20
    }
    
    // Create modal
    const modal = document.createElement('div')
    modal.id = 'user-profile-modal-hover'
    modal.className = 'fixed z-50 w-80 bg-white rounded-lg shadow-xl border border-gray-200'
    modal.style.cssText = `top: ${top}px; left: ${left}px;`
    
    modal.innerHTML = `
      <div class="flex items-center justify-between p-4 border-b border-gray-200">
        <h3 class="text-lg font-bold text-gray-900">User Profile</h3>
        <button class="w-8 h-8 rounded-full hover:bg-gray-100 flex items-center justify-center transition-colors hover-close-btn" type="button">
          <svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
      <div class="p-4">
        <div class="flex items-center gap-3 mb-4">
          <img src="${data.gravatar_url}" class="w-16 h-16 rounded-full object-cover" alt="${data.name}">
          <div class="flex-1 min-w-0">
            <div class="text-lg font-bold text-gray-900 truncate">${data.name}</div>
            <div class="text-sm text-gray-600 truncate">${data.email}</div>
          </div>
        </div>
        <div class="bg-gray-50 rounded-lg p-4 mb-4">
          <div class="flex items-center justify-around">
            <div class="text-center">
              <div class="text-2xl font-bold text-gray-900">${data.microposts_count}</div>
              <div class="text-xs text-gray-600 mt-1">Microposts</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-gray-900">${data.following_count}</div>
              <div class="text-xs text-gray-600 mt-1">Following</div>
            </div>
            <div class="text-center">
              <div class="text-2xl font-bold text-gray-900">${data.followers_count}</div>
              <div class="text-xs text-gray-600 mt-1">Followers</div>
            </div>
          </div>
        </div>
      </div>
      <div class="flex gap-2 p-4 border-t border-gray-200">
        <a href="/users/${data.id}" class="flex-1 bg-blue-600 text-white text-center px-4 py-2 rounded-lg font-semibold hover:bg-blue-700 transition-colors">View Full Profile</a>
        <button class="flex-1 bg-gray-100 text-gray-800 text-center px-4 py-2 rounded-lg font-semibold hover:bg-gray-200 transition-colors hover-close-btn" type="button">Close</button>
      </div>
    `
    
    document.body.appendChild(modal)
    
    let hideTimeout
    
    // Keep modal visible when hovering over it
    modal.addEventListener('mouseenter', () => {
      clearTimeout(hideTimeout)
    })
    
    modal.addEventListener('mouseleave', () => {
      hideTimeout = setTimeout(() => {
        modal.remove()
      }, 200)
    })
    
    // Close buttons
    modal.querySelectorAll('.hover-close-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        modal.remove()
      })
    })
    
    return modal
  } catch (error) {
    console.error('Error fetching user:', error)
    return null
  }
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

// ===== Header Search Dropdown =====
function initHeaderSearch() {
  const searchInput = document.getElementById('header-search-input')
  const searchContainer = document.getElementById('search-container')
  const searchDropdown = document.getElementById('search-dropdown')
  const toggleFiltersBtn = document.getElementById('toggle-filters')
  const filterOptions = document.getElementById('filter-options')
  const filterArrow = document.getElementById('filter-arrow')
  const applyFiltersBtn = document.getElementById('apply-filters')
  const clearFiltersBtn = document.getElementById('clear-filters')
  
  if (!searchInput || !searchDropdown) return
  
  let searchTimeout
  let recentSearches = JSON.parse(localStorage.getItem('recentSearches') || '[]')
  let searchFilters = {
    min_followers: null,
    min_following: null,
    filter: null
  }
  
  // Toggle filter options in dropdown
  console.log('Toggle filters button:', toggleFiltersBtn)
  console.log('Filter options:', filterOptions)
  console.log('Filter arrow:', filterArrow)
  
  if (toggleFiltersBtn && filterOptions && filterArrow) {
    console.log('Adding click listener to toggle filters button')
    toggleFiltersBtn.addEventListener('click', (e) => {
      console.log('Toggle filters clicked!')
      e.stopPropagation()
      filterOptions.classList.toggle('hidden')
      filterArrow.classList.toggle('rotate-180')
    })
  } else {
    console.warn('Filter elements not found:', { toggleFiltersBtn, filterOptions, filterArrow })
  }
  
  // Render recent searches
  function renderRecentSearches() {
    const recentList = document.getElementById('recent-searches-list')
    if (!recentList) return
    
    if (recentSearches.length === 0) {
      recentList.innerHTML = '<div class="p-4 text-center text-sm text-gray-500">No recent searches</div>'
      return
    }
    
    recentList.innerHTML = recentSearches.slice(0, 8).map(user => `
      <a href="/users/${user.id}" class="flex items-center gap-3 p-2 hover:bg-gray-100 rounded-lg transition-colors group">
        <img src="${user.avatar_url}" class="w-10 h-10 rounded-full object-cover" alt="${user.name}">
        <div class="flex-1 min-w-0">
          <div class="font-semibold text-gray-900 truncate">${escapeHtml(user.name)}</div>
          ${user.relationship ? `<div class="text-xs text-gray-600">${escapeHtml(user.relationship)}</div>` : ''}
        </div>
        <button class="opacity-0 group-hover:opacity-100 w-6 h-6 rounded-full hover:bg-gray-200 flex items-center justify-center transition-opacity remove-recent-search" data-user-id="${user.id}" type="button" onclick="event.stopPropagation(); event.preventDefault();">
          <svg class="w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </a>
    `).join('')
    
    // Add remove handlers
    recentList.querySelectorAll('.remove-recent-search').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation()
        e.preventDefault()
        const userId = parseInt(btn.dataset.userId)
        recentSearches = recentSearches.filter(u => u.id !== userId)
        localStorage.setItem('recentSearches', JSON.stringify(recentSearches))
        renderRecentSearches()
      })
    })
  }
  
  // Clear recent searches
  const clearRecentBtn = document.getElementById('clear-recent')
  if (clearRecentBtn) {
    clearRecentBtn.addEventListener('click', () => {
      recentSearches = []
      localStorage.setItem('recentSearches', JSON.stringify(recentSearches))
      renderRecentSearches()
    })
  }
  
  // Apply filters
  if (applyFiltersBtn) {
    applyFiltersBtn.addEventListener('click', (e) => {
      e.stopPropagation()
      const minFollowers = document.getElementById('filter-min-followers')?.value
      const minFollowing = document.getElementById('filter-min-following')?.value
      const filterType = document.getElementById('filter-type')?.value
      
      searchFilters.min_followers = minFollowers ? parseInt(minFollowers) : null
      searchFilters.min_following = minFollowing ? parseInt(minFollowing) : null
      searchFilters.filter = filterType || null
      
      // Re-run search with filters
      const query = searchInput.value.trim()
      if (query) {
        performSearch(query)
      }
    })
  }
  
  // Clear filters
  if (clearFiltersBtn) {
    clearFiltersBtn.addEventListener('click', (e) => {
      e.stopPropagation()
      searchFilters = {
        min_followers: null,
        min_following: null,
        filter: null
      }
      
      if (document.getElementById('filter-min-followers')) {
        document.getElementById('filter-min-followers').value = ''
      }
      if (document.getElementById('filter-min-following')) {
        document.getElementById('filter-min-following').value = ''
      }
      if (document.getElementById('filter-type')) {
        document.getElementById('filter-type').value = ''
      }
      
      // Re-run search without filters
      const query = searchInput.value.trim()
      if (query) {
        performSearch(query)
      }
    })
  }
  
  // Search function
  async function performSearch(query) {
    const recentSection = document.getElementById('search-recent')
    const resultsSection = document.getElementById('search-results')
    const resultsList = document.getElementById('search-results-list')
    const loadingSection = document.getElementById('search-loading')
    const emptySection = document.getElementById('search-empty')
    
    if (!query || query.trim() === '') {
      // Show recent searches
      recentSection.classList.remove('hidden')
      resultsSection.classList.add('hidden')
      loadingSection.classList.add('hidden')
      emptySection.classList.add('hidden')
      renderRecentSearches()
      return
    }
    
    // Hide recent, show loading
    recentSection.classList.add('hidden')
    resultsSection.classList.remove('hidden')
    resultsList.innerHTML = ''
    loadingSection.classList.remove('hidden')
    emptySection.classList.add('hidden')
    searchDropdown.classList.remove('hidden')
    
    try {
      // Build query params with filters
      const params = new URLSearchParams({ q: query })
      if (searchFilters.min_followers) params.append('min_followers', searchFilters.min_followers)
      if (searchFilters.min_following) params.append('min_following', searchFilters.min_following)
      if (searchFilters.filter) params.append('filter', searchFilters.filter)
      
      const response = await fetch(`/users/autocomplete?${params.toString()}`, {
        headers: {
          'Accept': 'application/json'
        }
      })
      
      if (!response.ok) throw new Error('Search failed')
      
      const data = await response.json()
      const users = data.users || []
      
      loadingSection.classList.add('hidden')
      
      if (users.length === 0) {
        emptySection.classList.remove('hidden')
        return
      }
      
      // Render results
      resultsList.innerHTML = users.map(user => `
        <a href="/users/${user.id}" class="flex items-center gap-3 p-2 hover:bg-gray-100 rounded-lg transition-colors search-result-item" data-user-id="${user.id}">
          <img src="${user.avatar_url}" class="w-10 h-10 rounded-full object-cover" alt="${user.name}">
          <div class="flex-1 min-w-0">
            <div class="font-semibold text-gray-900 truncate">${escapeHtml(user.name)}</div>
            ${user.relationship ? `<div class="text-xs text-gray-600">${escapeHtml(user.relationship)}</div>` : ''}
            ${user.new_posts_count > 0 ? `<div class="text-xs text-blue-600 flex items-center gap-1 mt-0.5">
              <span class="w-1.5 h-1.5 bg-blue-600 rounded-full"></span>
              ${user.new_posts_count} new
            </div>` : ''}
          </div>
        </a>
      `).join('')
      
      // Add click handlers to save to recent searches
      resultsList.querySelectorAll('.search-result-item').forEach(item => {
        item.addEventListener('click', () => {
          const userId = parseInt(item.dataset.userId)
          const user = users.find(u => u.id === userId)
          if (user) {
            // Remove if already exists
            recentSearches = recentSearches.filter(u => u.id !== userId)
            // Add to front
            recentSearches.unshift({
              id: user.id,
              name: user.name,
              avatar_url: user.avatar_url,
              relationship: user.relationship
            })
            // Keep only last 8
            recentSearches = recentSearches.slice(0, 8)
            localStorage.setItem('recentSearches', JSON.stringify(recentSearches))
          }
        })
      })
      
    } catch (error) {
      console.error('Search error:', error)
      loadingSection.classList.add('hidden')
      emptySection.classList.remove('hidden')
      emptySection.innerHTML = '<div class="text-sm text-gray-500">Error searching. Please try again.</div>'
    }
  }
  
  // Input handler with debounce
  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.trim()
    clearTimeout(searchTimeout)
    
    if (query === '') {
      performSearch('')
      return
    }
    
    searchTimeout = setTimeout(() => {
      performSearch(query)
    }, 300) // 300ms debounce
  })
  
  // Show dropdown on focus
  searchInput.addEventListener('focus', () => {
    const query = searchInput.value.trim()
    if (query === '') {
      // Show recent searches
      document.getElementById('search-recent').classList.remove('hidden')
      document.getElementById('search-results').classList.add('hidden')
      renderRecentSearches()
    }
    searchDropdown.classList.remove('hidden')
  })
  
  // Hide dropdown when clicking outside
  document.addEventListener('click', (e) => {
    if (!searchContainer.contains(e.target) && !searchDropdown.contains(e.target)) {
      searchDropdown.classList.add('hidden')
    }
  })
  
  // Initialize recent searches on load
  renderRecentSearches()
}

// Helper: Escape HTML
function escapeHtml(text) {
  const div = document.createElement('div')
  div.textContent = text
  return div.innerHTML
}

// Export for use in other modules
window.UserActions = {
  initUserFeatures,
  initAjaxPagination,
  initUserFilter,
  initUserProfileModal,
  showUserProfileModal,
  initHeaderSearch
}
