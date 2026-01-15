// Comments functionality
document.addEventListener('DOMContentLoaded', initializeComments);
document.addEventListener('turbo:load', initializeComments);
document.addEventListener('turbo:render', initializeComments);

function initializeComments() {
    // Handle comment form submissions
    document.querySelectorAll('.new-comment-form').forEach(form => {
        if (form.dataset.commentsBound) return;
        form.dataset.commentsBound = 'true';

        form.addEventListener('submit', handleCommentSubmit);
    });

    // Handle comment deletion
    document.querySelectorAll('.delete-comment').forEach(link => {
        if (link.dataset.commentsBound) return;
        link.dataset.commentsBound = 'true';

        link.addEventListener('click', handleCommentDelete);
    });
}

function handleCommentSubmit(e) {
    e.preventDefault();

    const form = e.target;
    const input = form.querySelector('.comment-input');
    const content = input.value.trim();

    if (!content) {
        alert('Comment cannot be blank');
        return;
    }

    const formData = new FormData(form);
    const micropostId = form.action.match(/\/microposts\/(\d+)/)[1];

    fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
            'Accept': 'application/json'
        }
    })
        .then(resp => resp.json())
        .then(data => {
            if (data.comment) {
                // Clear input
                input.value = '';

                // Add new comment to the list
                addCommentToList(micropostId, data.comment);

                // Update comment count
                updateCommentCount(micropostId);
            } else if (data.errors) {
                alert(data.errors.join(', '));
            }
        })
        .catch(err => {
            console.error('Error posting comment:', err);
            alert('Failed to post comment');
        });
}

function handleCommentDelete(e) {
    e.preventDefault();

    if (!confirm('Are you sure you want to delete this comment?')) {
        return;
    }

    const link = e.currentTarget;
    const commentId = link.dataset.commentId;
    const micropostId = link.dataset.micropostId;

    fetch(`/microposts/${micropostId}/comments/${commentId}`, {
        method: 'DELETE',
        headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
            'Accept': 'application/json'
        }
    })
        .then(() => {
            // Remove comment from DOM
            const commentItem = link.closest('.comment-item');
            if (commentItem) {
                commentItem.remove();
            }

            // Update comment count
            updateCommentCount(micropostId);
        })
        .catch(err => {
            console.error('Error deleting comment:', err);
            alert('Failed to delete comment');
        });
}

function addCommentToList(micropostId, comment) {
    const section = document.querySelector(`.micropost-comments-section[data-micropost-id="${micropostId}"]`);
    if (!section) return;

    const commentsList = section.querySelector('.comments-list');
    if (!commentsList) return;

    const commentHTML = `
        <div class="comment-item" data-comment-id="${comment.id}">
            <a href="/users/${comment.user.id}" class="comment-avatar">
                <img src="${comment.user.gravatar_url}" alt="${comment.user.name}" width="32" height="32" style="border-radius: 50%;">
            </a>
            <div class="comment-content">
                <div class="comment-header">
                    <a href="/users/${comment.user.id}" class="comment-author">${comment.user.name}</a>
                    <span class="comment-time">just now</span>
                </div>
                <div class="comment-text">${escapeHtml(comment.content)}</div>
                <div class="comment-actions">
                    <a class="delete-comment" href="#" data-comment-id="${comment.id}" data-micropost-id="${micropostId}">
                        <i class="glyphicon glyphicon-trash"></i>
                    </a>
                </div>
            </div>
        </div>
    `;

    commentsList.insertAdjacentHTML('beforeend', commentHTML);

    // Re-bind delete handler for new comment
    const newComment = commentsList.lastElementChild;
    const deleteLink = newComment.querySelector('.delete-comment');
    if (deleteLink) {
        deleteLink.addEventListener('click', handleCommentDelete);
    }
}

function updateCommentCount(micropostId) {
    const countElement = document.querySelector(`.comment-count[data-micropost-id="${micropostId}"]`);
    if (!countElement) return;

    const section = document.querySelector(`.micropost-comments-section[data-micropost-id="${micropostId}"]`);
    if (!section) return;

    const commentsCount = section.querySelectorAll('.comment-item').length;
    countElement.textContent = commentsCount;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

export { initializeComments };
