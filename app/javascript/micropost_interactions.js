// Micropost Interactions: Like, Comment, Share
let interactionsInitialized = false;

function initializeMicropostInteractions() {
    if (interactionsInitialized) {
        return;
    }
    interactionsInitialized = true;

    // Like button handler
    document.addEventListener('click', function (e) {
        if (e.target.closest('.like-btn')) {
            const likeBtn = e.target.closest('.like-btn');
            handleLike(likeBtn);
        }
    });

    // Comment button handler (placeholder for now)
    document.addEventListener('click', function (e) {
        if (e.target.closest('.comment-btn')) {
            const commentBtn = e.target.closest('.comment-btn');
            handleComment(commentBtn);
        }
    });

    // Share button handler (copy link)
    document.addEventListener('click', function (e) {
        if (e.target.closest('.share-btn')) {
            const shareBtn = e.target.closest('.share-btn');
            handleShare(shareBtn);
        }
    });
}

// Handle like button toggle
function handleLike(likeBtn) {
    const micropostId = likeBtn.dataset.micropostId;
    const isLiked = likeBtn.classList.contains('liked');

    // Toggle liked state
    likeBtn.classList.toggle('liked');

    // Update like count (this is hardcoded for now)
    const likeCountElement = likeBtn.closest('.micropost-card').querySelector('.like-count');
    if (likeCountElement) {
        let currentCount = parseInt(likeCountElement.textContent);
        if (isLiked) {
            likeCountElement.textContent = currentCount - 1;
        } else {
            likeCountElement.textContent = currentCount + 1;
        }
    }

    // TODO: Send AJAX request to backend to persist like
    // fetch(`/microposts/${micropostId}/like`, {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    //   }
    // })
}

// Handle comment button (placeholder)
function handleComment(commentBtn) {
    const micropostId = commentBtn.dataset.micropostId;

    // Show comment section or modal
    showFlashMessage('Comment functionality coming soon!', 'info');

    // TODO: Implement comment functionality
    // Could show a comment form inline or in a modal
}

// Handle share button (copy link)
function handleShare(shareBtn) {
    const micropostId = shareBtn.dataset.micropostId;
    const micropostUrl = `${window.location.origin}/microposts/${micropostId}`;

    // Copy to clipboard
    if (navigator.clipboard) {
        navigator.clipboard.writeText(micropostUrl).then(function () {
            showFlashMessage('Link copied to clipboard!', 'success');

            // Visual feedback on button
            const originalText = shareBtn.innerHTML;
            shareBtn.innerHTML = '<i class="glyphicon glyphicon-ok"></i> <span>Copied!</span>';
            shareBtn.style.color = '#17bf63';

            setTimeout(function () {
                shareBtn.innerHTML = originalText;
                shareBtn.style.color = '';
            }, 2000);
        }).catch(function (err) {
            console.error('Failed to copy:', err);
            showFallbackShare(micropostUrl);
        });
    } else {
        // Fallback for older browsers
        showFallbackShare(micropostUrl);
    }
}

// Fallback share method
function showFallbackShare(url) {
    const input = document.createElement('input');
    input.value = url;
    input.style.position = 'fixed';
    input.style.top = '-1000px';
    document.body.appendChild(input);
    input.select();

    try {
        document.execCommand('copy');
        showFlashMessage('Link copied to clipboard!', 'success');
    } catch (err) {
        // If all else fails, show the URL
        prompt('Copy this link:', url);
    }

    document.body.removeChild(input);
}

// Show flash message (reuse from micropost_ajax.js if available)
function showFlashMessage(message, type) {
    // Check if function exists from micropost_ajax.js
    if (typeof window.showFlashMessage === 'function') {
        window.showFlashMessage(message, type);
        return;
    }

    // Otherwise create our own
    const alertClass = type === 'success' ? 'alert-success' :
        type === 'error' ? 'alert-danger' :
            'alert-info';

    const flashDiv = document.createElement('div');
    flashDiv.className = `alert ${alertClass} flash-message`;
    flashDiv.style.cssText = 'position:fixed;top:20px;right:20px;z-index:9999;min-width:300px;';
    flashDiv.textContent = message;

    document.body.appendChild(flashDiv);

    setTimeout(function () {
        flashDiv.style.opacity = '0';
        flashDiv.style.transition = 'opacity 0.5s';
        setTimeout(function () {
            if (flashDiv.parentNode) {
                flashDiv.parentNode.removeChild(flashDiv);
            }
        }, 500);
    }, 3000);
}

// Initialize on page load and Turbo events
document.addEventListener('DOMContentLoaded', initializeMicropostInteractions);
document.addEventListener('turbo:load', initializeMicropostInteractions);
document.addEventListener('turbo:render', initializeMicropostInteractions);

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        initializeMicropostInteractions,
        handleLike,
        handleComment,
        handleShare
    };
}
