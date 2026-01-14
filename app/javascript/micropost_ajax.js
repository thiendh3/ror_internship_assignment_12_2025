// Micropost AJAX operations
let micropostHandlersInitialized = false;

function initializeMicropostAjax() {
    // Prevent multiple initializations
    if (micropostHandlersInitialized) {
        return;
    }
    micropostHandlersInitialized = true;

    // AJAX form submission for creating micropost
    const micropostForm = document.querySelector('#new_micropost');
    if (micropostForm) {
        micropostForm.addEventListener('submit', function (e) {
            const submitButton = this.querySelector('input[type="submit"]');
            if (submitButton.dataset.ajaxSubmit !== 'true') {
                return; // Allow normal form submission
            }

            e.preventDefault();
            const formData = new FormData(this);

            fetch(this.action, {
                method: 'POST',
                body: formData,
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'Accept': 'application/json'
                }
            })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // Clear form
                        this.reset();
                        document.getElementById('image-preview-container').style.display = 'none';

                        // Add new micropost to feed
                        const feedList = document.querySelector('.microposts');
                        if (feedList) {
                            const tempDiv = document.createElement('div');
                            tempDiv.innerHTML = data.micropost;
                            feedList.insertBefore(tempDiv.firstChild, feedList.firstChild);
                            showFlashMessage('Micropost created!', 'success');
                        }
                    } else {
                        showFlashMessage(data.errors.join(', '), 'danger');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showFlashMessage('An error occurred', 'danger');
                });
        });
    }

    // Delete micropost with AJAX
    document.addEventListener('click', function (e) {
        if (e.target.classList.contains('delete-micropost')) {
            e.preventDefault();

            if (!confirm('Are you sure you want to delete this micropost?')) {
                return;
            }

            const micropostId = e.target.dataset.micropostId;
            const micropostElement = document.getElementById(`micropost-${micropostId}`);

            fetch(`/microposts/${micropostId}`, {
                method: 'DELETE',
                headers: {
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
                    'X-Requested-With': 'XMLHttpRequest',
                    'Accept': 'application/json'
                }
            })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        micropostElement.remove();
                        showFlashMessage('Micropost deleted', 'success');
                    } else {
                        showFlashMessage(data.error || 'Error deleting micropost', 'danger');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    showFlashMessage('An error occurred', 'danger');
                });
        }
    });

    // Show micropost in modal
    document.addEventListener('click', function (e) {
        if (e.target.classList.contains('view-micropost')) {
            e.preventDefault();
            const micropostId = e.target.dataset.micropostId;

            fetch(`/microposts/${micropostId}`, {
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                    'Accept': 'application/json'
                }
            })
                .then(response => response.json())
                .then(data => {
                    showMicropostModal(data.micropost);
                })
                .catch(error => {
                    console.error('Error:', error);
                    showFlashMessage('Error loading micropost', 'danger');
                });
        }
    });

    // Edit micropost inline
    document.addEventListener('click', function (e) {
        if (e.target.classList.contains('edit-micropost')) {
            e.preventDefault();
            const micropostId = e.target.dataset.micropostId;
            const micropostElement = document.getElementById(`micropost-${micropostId}`);
            const micropostBody = micropostElement.querySelector('.micropost-body');
            const contentElement = micropostBody.querySelector('.micropost-content');
            const imageElement = micropostBody.querySelector('.micropost-image');
            const hashtagsElement = micropostBody.querySelector('.micropost-hashtags');

            // Get content
            let currentContent = contentElement.textContent.trim();

            // Add hashtags back to content for editing
            if (hashtagsElement) {
                const hashtags = Array.from(hashtagsElement.querySelectorAll('.hashtag-badge'))
                    .map(badge => badge.textContent.trim())
                    .join(' ');
                if (hashtags) {
                    currentContent = currentContent + ' ' + hashtags;
                }
            }

            const hasImage = imageElement !== null;

            // Save original HTML for cancel
            const originalBodyHTML = micropostBody.innerHTML;

            // Create edit form
            const editForm = document.createElement('form');
            editForm.className = 'edit-micropost-form';
            editForm.innerHTML = `
        <textarea class="form-control" rows="3" name="content" required>${currentContent}</textarea>
        <div style="margin-top: 10px;">
          ${hasImage ? `
            <div class="current-image-preview">
              <img src="${imageElement.querySelector('img').src}" style="max-width: 200px; border-radius: 8px;">
              <label style="display: block; margin-top: 5px;">
                <input type="checkbox" name="remove_image" value="1"> Remove image
              </label>
            </div>
          ` : ''}
          <div style="margin-top: 10px;">
            <label>Upload new image:</label>
            <input type="file" name="image" accept="image/*" class="form-control" style="height: auto;">
            <div class="image-preview-container" style="margin-top: 10px; display: none;">
              <img class="image-preview" style="max-width: 200px; border-radius: 8px;">
            </div>
          </div>
        </div>
        <div class="edit-actions" style="margin-top: 10px;">
          <button type="submit" class="btn btn-primary btn-sm">Save</button>
          <button type="button" class="btn btn-default btn-sm cancel-edit">Cancel</button>
        </div>
      `;

            // Replace content with form
            micropostBody.innerHTML = '';
            micropostBody.appendChild(editForm);

            // Handle image preview
            const imageInput = editForm.querySelector('input[type="file"]');
            const previewContainer = editForm.querySelector('.image-preview-container');
            const previewImg = editForm.querySelector('.image-preview');

            imageInput.addEventListener('change', function (e) {
                const file = e.target.files[0];
                if (file) {
                    const reader = new FileReader();
                    reader.onload = function (e) {
                        previewImg.src = e.target.result;
                        previewContainer.style.display = 'block';
                    };
                    reader.readAsDataURL(file);
                } else {
                    previewContainer.style.display = 'none';
                }
            });

            // Handle form submission
            editForm.addEventListener('submit', function (e) {
                e.preventDefault();
                const formData = new FormData();
                const newContent = this.querySelector('textarea').value;
                const imageFile = this.querySelector('input[type="file"]').files[0];
                const removeImage = this.querySelector('input[name="remove_image"]');

                formData.append('micropost[content]', newContent);

                if (imageFile) {
                    formData.append('micropost[image]', imageFile);
                }

                if (removeImage && removeImage.checked) {
                    formData.append('micropost[remove_image]', '1');
                }

                fetch(`/microposts/${micropostId}`, {
                    method: 'PATCH',
                    headers: {
                        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'application/json'
                    },
                    body: formData
                })
                    .then(response => response.json())
                    .then(data => {
                        if (data.success) {
                            // Replace entire micropost with updated HTML
                            const tempDiv = document.createElement('div');
                            tempDiv.innerHTML = data.micropost;
                            micropostElement.replaceWith(tempDiv.firstChild);
                            showFlashMessage('Micropost updated', 'success');
                        } else {
                            showFlashMessage(data.errors.join(', '), 'danger');
                        }
                    })
                    .catch(error => {
                        console.error('Error:', error);
                        showFlashMessage('An error occurred', 'danger');
                    });
            });

            // Handle cancel
            editForm.querySelector('.cancel-edit').addEventListener('click', function () {
                // Restore original content
                micropostBody.innerHTML = originalBodyHTML;
            });
        }
    });
}

// Show micropost in modal
function showMicropostModal(micropost) {
    let modal = document.getElementById('micropost-modal');

    if (!modal) {
        // Create modal if it doesn't exist
        modal = document.createElement('div');
        modal.id = 'micropost-modal';
        modal.className = 'modal fade';
        modal.innerHTML = `
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal">&times;</button>
            <h4 class="modal-title">Micropost Details</h4>
          </div>
          <div class="modal-body"></div>
          <div class="modal-footer">
            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
          </div>
        </div>
      </div>
    `;
        document.body.appendChild(modal);
    }

    // Populate modal
    const modalBody = modal.querySelector('.modal-body');
    let imageHtml = '';
    if (micropost.display_image_url) {
        imageHtml = `<img src="${micropost.display_image_url}" class="img-responsive" style="margin: 10px 0;">`;
    }

    const hashtagsHtml = micropost.hashtags && micropost.hashtags.length > 0
        ? micropost.hashtags.map(h => `<span class="hashtag-badge">#${h.name}</span>`).join(' ')
        : '';

    modalBody.innerHTML = `
    <div class="micropost-detail">
      <p><strong>Author:</strong> ${micropost.user.name}</p>
      <p><strong>Content:</strong></p>
      <p>${micropost.content}</p>
      ${imageHtml}
      ${hashtagsHtml ? `<p><strong>Hashtags:</strong> ${hashtagsHtml}</p>` : ''}
      <p><small class="text-muted">Posted ${timeAgo(micropost.created_at)}</small></p>
    </div>
  `;

    // Show modal using Bootstrap's modal
    $(modal).modal('show');
}

// Helper function for flash messages
function showFlashMessage(message, type) {
    const container = document.querySelector('.container');
    const alert = document.createElement('div');
    alert.className = `alert alert-${type} alert-dismissible`;
    alert.innerHTML = `
    <button type="button" class="close" data-dismiss="alert">&times;</button>
    ${message}
  `;
    container.insertBefore(alert, container.firstChild);

    setTimeout(() => {
        alert.remove();
    }, 3000);
}

// Helper function for time ago
function timeAgo(dateString) {
    const date = new Date(dateString);
    const seconds = Math.floor((new Date() - date) / 1000);

    let interval = Math.floor(seconds / 31536000);
    if (interval > 1) return interval + " years ago";
    if (interval === 1) return "1 year ago";

    interval = Math.floor(seconds / 2592000);
    if (interval > 1) return interval + " months ago";
    if (interval === 1) return "1 month ago";

    interval = Math.floor(seconds / 86400);
    if (interval > 1) return interval + " days ago";
    if (interval === 1) return "1 day ago";

    interval = Math.floor(seconds / 3600);
    if (interval > 1) return interval + " hours ago";
    if (interval === 1) return "1 hour ago";

    interval = Math.floor(seconds / 60);
    if (interval > 1) return interval + " minutes ago";
    if (interval === 1) return "1 minute ago";

    return "just now";
}

// Initialize on page load and Turbo events
document.addEventListener('DOMContentLoaded', initializeMicropostAjax);
document.addEventListener('turbo:load', initializeMicropostAjax);
document.addEventListener('turbo:render', initializeMicropostAjax);
