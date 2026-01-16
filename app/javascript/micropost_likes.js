// Handle reactions with AJAX (event delegation)
let reactionsInitialized = false;

function initializeMicropostLikes() {
    if (reactionsInitialized) return;
    reactionsInitialized = true;

    document.addEventListener('click', function (e) {
        const option = e.target.closest('.reaction-option');
        const toggle = e.target.closest('.reaction-toggle');
        if (!option && !toggle) return;

        e.preventDefault();

        const dropdown = (option || toggle).closest('.reaction-dropdown');
        if (!dropdown) return;

        const micropostId = dropdown.dataset.micropostId;
        const currentReaction = dropdown.dataset.currentReaction || null;
        const reactionType = option ? option.dataset.reactionType : 'like';
        const url = `/microposts/${micropostId}/like`;
        const method = currentReaction === reactionType ? 'DELETE' : 'POST';

        const targetButton = option || toggle;
        if (targetButton.disabled) return;
        targetButton.disabled = true;

        fetch(url, {
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
                'Accept': 'application/json'
            },
            body: method === 'POST' ? JSON.stringify({ reaction_type: reactionType }) : null
        })
            .then(response => response.json())
            .then(data => {
                if (data.error) {
                    alert(data.error);
                    return;
                }

                dropdown.dataset.currentReaction = data.liked ? data.reaction_type : '';
                updateReactionToggle(dropdown, data.liked ? data.reaction_type : null);

                const likeCountElement = document.querySelector(
                    `.like-count[data-micropost-id="${micropostId}"]`
                );
                if (likeCountElement) {
                    likeCountElement.textContent = data.likes_count;
                }

                if (data.reaction_counts) {
                    updateReactionCounts(micropostId, data.reaction_counts, data.likes_count);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('An error occurred. Please try again.');
            })
            .finally(() => {
                targetButton.disabled = false;
            });
    });
}

function updateReactionCounts(micropostId, reactionCounts, totalCount) {
    const summary = document.querySelector(
        `.reaction-summary[data-micropost-id="${micropostId}"]`
    );
    if (!summary) return;

    const totalEl = summary.querySelector('[data-reaction-total]');
    if (totalEl && typeof totalCount !== 'undefined') totalEl.textContent = totalCount;

    toggleReactionIcon(summary, 'like', reactionCounts.like || 0);
    toggleReactionIcon(summary, 'love', reactionCounts.love || 0);
    toggleReactionIcon(summary, 'haha', reactionCounts.haha || 0);
}

function toggleReactionIcon(summary, type, count) {
    const icon = summary.querySelector(`[data-reaction-type="${type}"]`);
    if (!icon) return;

    icon.style.display = count > 0 ? 'inline-flex' : 'none';
}

function updateReactionToggle(dropdown, reactionType) {
    const toggle = dropdown.querySelector('.reaction-toggle');
    if (!toggle) return;

    const emoji = toggle.querySelector('.reaction-emoji');
    const label = toggle.querySelector('.reaction-label');

    toggle.classList.remove('active');
    toggle.classList.remove('muted');

    switch (reactionType) {
        case 'love':
            emoji.textContent = '❤️';
            label.textContent = 'Love';
            toggle.classList.add('active');
            break;
        case 'haha':
            emoji.textContent = '😂';
            label.textContent = 'Haha';
            toggle.classList.add('active');
            break;
        case 'like':
            emoji.textContent = '👍';
            label.textContent = 'Like';
            toggle.classList.add('active');
            break;
        default:
            emoji.textContent = '👍';
            label.textContent = 'Like';
            toggle.classList.add('muted');
            break;
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', initializeMicropostLikes);
document.addEventListener('turbo:load', initializeMicropostLikes);
document.addEventListener('turbo:render', initializeMicropostLikes);

// Open modal showing likers when clicking likes count
function initializeLikersModal() {
    document.addEventListener('click', function (e) {
        const el = e.target.closest('.reaction-summary, .like-count');
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
                initializeReactionTabs();
            })
            .catch(err => {
                console.error('Fetch error:', err);
                alert('Could not load likes list: ' + err.message);
            });
    });
}

function initializeReactionTabs() {
    const tabs = document.querySelectorAll('.reaction-tab');
    const listItems = document.querySelectorAll('.reaction-list [data-reaction-type]');
    if (!tabs.length || !listItems.length) return;

    tabs.forEach(tab => {
        tab.addEventListener('click', function () {
            tabs.forEach(t => t.classList.remove('active'));
            this.classList.add('active');

            const filter = this.dataset.filter;
            listItems.forEach(item => {
                if (filter === 'all' || item.dataset.reactionType === filter) {
                    item.style.display = 'flex';
                } else {
                    item.style.display = 'none';
                }
            });
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
