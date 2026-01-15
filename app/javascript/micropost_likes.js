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
