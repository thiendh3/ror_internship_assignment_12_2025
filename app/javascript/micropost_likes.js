// Handle like/unlike micropost with AJAX
function initializeMicropostLikes() {
    const likeButtons = document.querySelectorAll('.like-btn');

    likeButtons.forEach(button => {
        button.addEventListener('click', function (e) {
            e.preventDefault();

            if (this.disabled) return;

            const micropostId = this.dataset.micropostId;
            const action = this.dataset.action;
            const url = `/microposts/${micropostId}/like`;
            const method = action === 'like' ? 'POST' : 'DELETE';

            // Disable button during request
            this.disabled = true;

            fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
                    'Accept': 'application/json'
                }
            })
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        alert(data.error);
                        return;
                    }

                    // Update button state
                    const icon = this.querySelector('i');
                    const span = this.querySelector('span');

                    if (data.liked) {
                        // User just liked
                        icon.classList.remove('glyphicon-heart-empty');
                        icon.classList.add('glyphicon-heart');
                        span.textContent = 'Unlike';
                        this.classList.add('liked');
                        this.dataset.action = 'unlike';
                    } else {
                        // User just unliked
                        icon.classList.remove('glyphicon-heart');
                        icon.classList.add('glyphicon-heart-empty');
                        span.textContent = 'Like';
                        this.classList.remove('liked');
                        this.dataset.action = 'like';
                    }

                    // Update likes count
                    const likeCountElement = document.querySelector(
                        `.like-count[data-micropost-id="${micropostId}"]`
                    );
                    if (likeCountElement) {
                        likeCountElement.textContent = data.likes_count;
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('An error occurred. Please try again.');
                })
                .finally(() => {
                    // Re-enable button
                    this.disabled = false;
                });
        });
    });
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', initializeMicropostLikes);
document.addEventListener('turbo:load', initializeMicropostLikes);
document.addEventListener('turbo:render', initializeMicropostLikes);

// Open modal showing likers when clicking likes count
function initializeLikersModal() {
    document.addEventListener('click', function (e) {
        const el = e.target.closest('.like-count');
        if (!el) return;

        e.preventDefault();
        e.stopPropagation();
        const micropostId = el.dataset.micropostId;
        if (!micropostId) {
            console.error('No micropost ID found on element:', el);
            return;
        }
        console.log('Fetching likes for micropost:', micropostId);

        // Fetch likers HTML
        fetch(`/microposts/${micropostId}/likes`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
            }
        })
            .then(resp => {
                console.log('Response status:', resp.status);
                if (!resp.ok) {
                    throw new Error(`HTTP error! status: ${resp.status}`);
                }
                return resp.json();
            })
            .then(data => {
                console.log('Received data:', data);
                if (data.error) {
                    alert(data.error);
                    return;
                }
                showModalWithContent(data.html);
            })
            .catch(err => {
                console.error('Fetch error:', err);
                alert('Could not load likes list: ' + err.message);
            });
    });
}

function showModalWithContent(html) {
    console.log('showModalWithContent called with HTML length:', html.length);
    console.log('HTML content:', html);

    // Build or reuse a Bootstrap-structured modal (works without Bootstrap JS)
    let modal = document.getElementById('likes-modal');
    let backdrop = document.querySelector('.modal-backdrop[data-for="likes-modal"]');

    if (!modal) {
        console.log('Creating new modal');
        modal = document.createElement('div');
        modal.id = 'likes-modal';
        modal.className = 'modal fade';
        modal.tabIndex = -1;
        modal.setAttribute('role', 'dialog');
        modal.innerHTML = `
          <div class="modal-dialog" role="document">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title">Likes</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                  <span aria-hidden="true">&times;</span>
                </button>
              </div>
              <div class="modal-body"></div>
            </div>
          </div>`;
        document.body.appendChild(modal);
        console.log('Modal created and appended to body');

        // close handlers
        const closeBtn = modal.querySelector('[data-dismiss="modal"]');
        closeBtn.addEventListener('click', (e) => {
            e.preventDefault();
            hideModal();
        });

        modal.addEventListener('click', (ev) => {
            if (ev.target === modal) {
                hideModal();
            }
        });
    } else {
        console.log('Reusing existing modal');
    }

    function hideModal() {
        console.log('Hiding modal');
        modal.classList.remove('show');
        modal.style.display = 'none';
        const backdrop = document.querySelector('.modal-backdrop[data-for="likes-modal"]');
        if (backdrop) {
            backdrop.remove();
        }
    }

    // Insert content
    const modalBody = modal.querySelector('.modal-body');
    modalBody.innerHTML = html;
    console.log('Content inserted into modal-body:', modalBody.innerHTML.length, 'chars');

    // show modal + backdrop
    if (!backdrop) {
        console.log('Creating backdrop');
        backdrop = document.createElement('div');
        backdrop.className = 'modal-backdrop fade show';
        backdrop.setAttribute('data-for', 'likes-modal');
        document.body.appendChild(backdrop);
        backdrop.addEventListener('click', hideModal);
    }

    modal.style.display = 'block';
    console.log('Modal display set to block');

    // trigger CSS animation class
    setTimeout(() => {
        modal.classList.add('show');
        console.log('Show class added to modal');
    }, 10);
}

document.addEventListener('DOMContentLoaded', initializeLikersModal);
document.addEventListener('turbo:load', initializeLikersModal);
document.addEventListener('turbo:render', initializeLikersModal);
