// Follow/Unfollow functionality with AJAX

document.addEventListener('DOMContentLoaded', () => {
  initFollowButtons()
})

document.addEventListener('turbo:load', () => {
  initFollowButtons()
})

function initFollowButtons() {
  const followForm = document.getElementById('follow_form')
  if (!followForm) {
    console.log('Follow form not found')
    return
  }

  console.log('Initializing follow buttons')
  const forms = followForm.querySelectorAll('form')
  console.log('Found forms:', forms.length)
  
  forms.forEach(form => {
    if (form.dataset.initialized) return
    form.dataset.initialized = 'true'

    form.addEventListener('submit', async (e) => {
      e.preventDefault()
      console.log('Form submitted!')
      
      const button = form.querySelector('button[type="submit"]')
      if (!button) {
        console.log('Button not found')
        return
      }

      // Check if this is unfollow and confirm
      const method = form.method.toUpperCase()
      const isUnfollow = form.querySelector('input[name="_method"]')?.value === 'delete' || method === 'DELETE'
      
      if (isUnfollow) {
        const confirmed = confirm('Are you sure you want to unfollow this user?')
        if (!confirmed) return
      }

      // Disable button during request
      button.disabled = true
      const originalHTML = button.innerHTML

      try {
        const formData = new FormData(form)
        const method = form.method.toUpperCase()
        const url = form.action

        console.log('Sending request:', method, url)
        const response = await fetch(url, {
          method: method,
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
            'Accept': 'application/json'
          },
          body: method === 'POST' ? formData : null
        })

        if (!response.ok) throw new Error('Request failed')

        const data = await response.json()
        console.log('Response:', data)

        if (data.success) {
          // Update followers count
          updateFollowersCount(data.followers_count)

          // Toggle button state
          if (method === 'POST') {
            // Changed from Follow to Unfollow
            button.innerHTML = `
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
              </svg>
              <span>Unfollow</span>
            `
            button.className = 'px-4 py-2 bg-gray-200 text-gray-900 rounded-lg font-semibold hover:bg-gray-300 transition-colors flex items-center gap-2'
            
            // Update form to unfollow
            form.method = 'POST'
            form.action = `/relationships/${data.relationship_id}`
            
            // Add hidden _method field for DELETE
            let methodField = form.querySelector('input[name="_method"]')
            if (!methodField) {
              methodField = document.createElement('input')
              methodField.type = 'hidden'
              methodField.name = '_method'
              form.appendChild(methodField)
            }
            methodField.value = 'delete'
          } else {
            // Changed from Unfollow to Follow
            button.innerHTML = `
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
              </svg>
              <span>Follow</span>
            `
            button.className = 'px-4 py-2 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors flex items-center gap-2'
            
            // Update form to follow
            form.method = 'POST'
            form.action = '/relationships'
            
            // Remove _method field
            const methodField = form.querySelector('input[name="_method"]')
            if (methodField) methodField.remove()
            
            // Ensure followed_id is present
            let followedIdField = form.querySelector('input[name="relationship[followed_id]"]') ||
                                  form.querySelector('input[name="followed_id"]')
            if (!followedIdField) {
              followedIdField = document.createElement('input')
              followedIdField.type = 'hidden'
              followedIdField.name = 'relationship[followed_id]'
              // Get user ID from page
              const userId = document.querySelector('.user-name')?.dataset?.userId
              if (userId) {
                followedIdField.value = userId
                form.appendChild(followedIdField)
              }
            }
          }
        }
      } catch (error) {
        console.error('Error following/unfollowing:', error)
        button.innerHTML = originalHTML
      } finally {
        button.disabled = false
        // Re-initialize to handle new form state
        form.dataset.initialized = ''
        initFollowButtons()
      }
    })
  })
}

function updateFollowersCount(count) {
  // Update in profile header
  const followersCounts = document.querySelectorAll('.font-semibold')
  followersCounts.forEach(el => {
    if (el.nextElementSibling?.textContent?.includes('followers')) {
      el.textContent = count
    }
  })

  // Update in about tab
  const aboutFollowers = document.querySelector('.text-2xl.font-bold.text-blue-600')
  if (aboutFollowers && aboutFollowers.nextElementSibling?.textContent?.includes('Followers')) {
    aboutFollowers.textContent = count
  }
}

// Export for use in other modules
window.FollowActions = {
  initFollowButtons,
  updateFollowersCount
}
