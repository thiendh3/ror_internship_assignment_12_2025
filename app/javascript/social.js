// Social Features: Reactions, Comments, Shares

document.addEventListener('DOMContentLoaded', () => {
  initSocialFeatures();
});

document.addEventListener('turbo:load', () => {
  initSocialFeatures();
});

function initSocialFeatures() {
  initReactions();
  initComments();
  initShares();
  initShareActions();
}

// ========== SHARE ACTIONS ==========
function initShareActions() {
  // Delete share button
  document.querySelectorAll('.btn-delete-share').forEach(btn => {
    btn.addEventListener('click', handleDeleteShare);
  });
}

async function handleDeleteShare(e) {
  e.preventDefault();
  e.stopPropagation();
  
  if (!confirm('Delete this share?')) return;
  
  const btn = e.currentTarget;
  const shareId = btn.dataset.shareId;
  const originalMicropostId = btn.dataset.originalMicropostId || btn.dataset.micropostId;
  const shareEl = document.getElementById(`share-${shareId}`);
  
  // If original post was deleted, use a different endpoint
  const url = originalMicropostId ? `/microposts/${originalMicropostId}/shares/${shareId}` : `/shares/${shareId}`;
  
  try {
    const response = await fetch(url, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    });
    
    const data = await response.json();
    if (data.success) {
      if (shareEl) {
        shareEl.style.transition = 'opacity 0.3s ease-out';
        shareEl.style.opacity = '0';
        setTimeout(() => shareEl.remove(), 300);
      }
    } else {
      alert('Failed to delete share');
    }
  } catch (error) {
    console.error('Error deleting share:', error);
  }
}

// ========== REACTIONS ==========
function initReactions() {
  // Show reaction picker on hover
  document.querySelectorAll('.reaction-btn-wrapper').forEach(wrapper => {
    const picker = wrapper.querySelector('.reaction-picker');
    if (!picker) return;
    
    if (wrapper.dataset.reactionInitialized) return;
    wrapper.dataset.reactionInitialized = 'true';

    let hideTimeout;

    wrapper.addEventListener('mouseenter', () => {
      clearTimeout(hideTimeout);
      picker.classList.remove('hidden');
    });

    wrapper.addEventListener('mouseleave', () => {
      hideTimeout = setTimeout(() => picker.classList.add('hidden'), 300);
    });

    picker.addEventListener('mouseenter', () => clearTimeout(hideTimeout));
    picker.addEventListener('mouseleave', () => {
      hideTimeout = setTimeout(() => picker.classList.add('hidden'), 300);
    });
  });

  // Handle reaction selection
  document.querySelectorAll('.reaction-option:not([data-reaction-initialized])').forEach(btn => {
    btn.dataset.reactionInitialized = 'true';
    btn.addEventListener('click', handleReaction);
  });

  // Handle quick like (click on main button)
  document.querySelectorAll('.btn-reaction-trigger:not([data-quick-reaction-initialized])').forEach(btn => {
    btn.dataset.quickReactionInitialized = 'true';
    btn.addEventListener('click', handleQuickReaction);
  });

  // Comment reactions - picker hover
  document.querySelectorAll('.comment-reaction-wrapper').forEach(wrapper => {
    const picker = wrapper.querySelector('.comment-reaction-picker');
    if (!picker) return;
    
    if (wrapper.dataset.commentReactionInitialized) return;
    wrapper.dataset.commentReactionInitialized = 'true';

    let hideTimeout;
    wrapper.addEventListener('mouseenter', () => {
      clearTimeout(hideTimeout);
      picker.classList.remove('hidden');
    });
    wrapper.addEventListener('mouseleave', () => {
      hideTimeout = setTimeout(() => picker.classList.add('hidden'), 300);
    });
    picker.addEventListener('mouseenter', () => clearTimeout(hideTimeout));
    picker.addEventListener('mouseleave', () => {
      hideTimeout = setTimeout(() => picker.classList.add('hidden'), 300);
    });
  });

  // Comment reaction option click
  document.querySelectorAll('.comment-reaction-option:not([data-comment-reaction-option-initialized])').forEach(btn => {
    btn.dataset.commentReactionOptionInitialized = 'true';
    btn.addEventListener('click', handleCommentReactionOption);
  });

  // Comment quick reaction (main button)
  document.querySelectorAll('.btn-comment-reaction:not([data-comment-quick-reaction-initialized])').forEach(btn => {
    btn.dataset.commentQuickReactionInitialized = 'true';
    btn.addEventListener('click', handleCommentQuickReaction);
  });
}

async function handleReaction(e) {
  e.preventDefault();
  e.stopPropagation();
  
  const btn = e.currentTarget;
  const reactionType = btn.dataset.reactionType || btn.dataset.reaction;
  const micropostId = btn.dataset.micropostId;
  const picker = btn.closest('.reaction-picker');
  
  if (picker) picker.classList.add('hidden');
  
  if (!micropostId) {
    console.error('Missing micropostId for reaction');
    return;
  }
  
  await sendReaction(micropostId, reactionType, 'micropost');
}

async function handleQuickReaction(e) {
  e.preventDefault();
  e.stopPropagation();
  
  const btn = e.currentTarget;
  const micropostId = btn.dataset.micropostId;
  const currentReaction = btn.dataset.currentReaction || btn.dataset.reaction;
  
  if (!micropostId) {
    console.error('Missing micropostId for quick reaction');
    return;
  }
  
  if (currentReaction) {
    // Remove reaction
    await removeReaction(micropostId, 'micropost');
  } else {
    // Add like
    await sendReaction(micropostId, 'like', 'micropost');
  }
}

async function handleCommentReactionOption(e) {
  e.preventDefault();
  e.stopPropagation();
  
  const btn = e.currentTarget;
  const commentId = btn.dataset.commentId;
  const reactionType = btn.dataset.reactionType;
  const picker = btn.closest('.comment-reaction-picker');
  if (picker) picker.classList.add('hidden');
  
  await sendCommentReaction(commentId, reactionType);
}

async function handleCommentQuickReaction(e) {
  e.preventDefault();
  e.stopPropagation();
  
  const btn = e.currentTarget;
  const commentId = btn.dataset.commentId;
  const currentReaction = btn.dataset.currentReaction;
  
  if (currentReaction) {
    await removeCommentReaction(commentId);
  } else {
    await sendCommentReaction(commentId, 'like');
  }
}

async function sendCommentReaction(commentId, reactionType) {
  try {
    const response = await fetch(`/comments/${commentId}/reactions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ reaction_type: reactionType })
    });
    
    const data = await response.json();
    if (data.success) {
      updateCommentReactionUI(commentId, data.reactions_data);
    }
  } catch (error) {
    console.error('Error sending comment reaction:', error);
  }
}

async function removeCommentReaction(commentId) {
  try {
    const response = await fetch(`/comments/${commentId}/reactions`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    });
    
    const data = await response.json();
    if (data.success) {
      updateCommentReactionUI(commentId, data.reactions_data);
    }
  } catch (error) {
    console.error('Error removing comment reaction:', error);
  }
}

function updateCommentReactionUI(commentId, reactionsData) {
  const commentEl = document.querySelector(`[data-comment-id="${commentId}"]`);
  if (!commentEl) return;
  
  const btn = commentEl.querySelector('.btn-comment-reaction');
  if (btn) {
    btn.dataset.currentReaction = reactionsData.user_reaction || '';
    btn.classList.toggle('reacted', !!reactionsData.user_reaction);
    
    // Update emoji and text
    const emoji = reactionsData.user_reaction ? getReactionEmoji(reactionsData.user_reaction) : '👍';
    const text = reactionsData.user_reaction ? reactionsData.user_reaction.charAt(0).toUpperCase() + reactionsData.user_reaction.slice(1) : 'Like';
    
    const icon = btn.querySelector('.reaction-icon');
    const textEl = btn.querySelector('.reaction-text');
    if (icon) icon.textContent = emoji;
    if (textEl) textEl.textContent = text;
  }
  
  // Update display
  let display = commentEl.querySelector('.comment-reactions-display');
  if (reactionsData.total_count > 0) {
    if (!display) {
      display = document.createElement('div');
      display.className = 'comment-reactions-display';
      const wrapper = commentEl.querySelector('.comment-reaction-wrapper');
      if (wrapper) wrapper.after(display);
    }
    let html = '';
    if (reactionsData.top_reactions) {
      reactionsData.top_reactions.forEach(rt => {
        html += `<span class="reaction-icon-tiny">${getReactionEmoji(rt)}</span>`;
      });
    }
    html += `<span class="reaction-count">${reactionsData.total_count}</span>`;
    display.innerHTML = html;
  } else if (display) {
    display.remove();
  }
}

async function sendReaction(id, reactionType, targetType) {
  const url = targetType === 'micropost' 
    ? `/microposts/${id}/reactions`
    : `/comments/${id}/reactions`;
    
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ reaction_type: reactionType })
    });
    
    const data = await response.json();
    if (data.success) {
      updateReactionUI(id, targetType, data.reactions_data);
    }
  } catch (error) {
    console.error('Error sending reaction:', error);
  }
}

async function removeReaction(id, targetType) {
  const url = targetType === 'micropost'
    ? `/microposts/${id}/reactions`
    : `/comments/${id}/reactions`;
    
  try {
    const response = await fetch(url, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    });
    
    const data = await response.json();
    if (data.success) {
      updateReactionUI(id, targetType, data.reactions_data);
    }
  } catch (error) {
    console.error('Error removing reaction:', error);
  }
}

function updateReactionUI(id, targetType, reactionsData) {
  if (targetType === 'micropost') {
    const micropost = document.getElementById(`micropost-${id}`);
    if (!micropost) return;
    
    const btn = micropost.querySelector('.btn-reaction-trigger');
    const summary = micropost.querySelector('.reactions-summary .reactions-icons');
    
    if (btn) {
      btn.dataset.currentReaction = reactionsData.user_reaction || '';
      btn.classList.toggle('reacted', !!reactionsData.user_reaction);
      
      // Update button content with emoji and text
      const emoji = reactionsData.user_reaction ? getReactionEmoji(reactionsData.user_reaction) : '👍';
      const text = reactionsData.user_reaction ? reactionsData.user_reaction.charAt(0).toUpperCase() + reactionsData.user_reaction.slice(1) : 'Like';
      
      // Update emoji span
      const emojiSpan = btn.querySelector('span:first-child');
      if (emojiSpan) {
        emojiSpan.textContent = emoji;
      }
      
      // Update text span
      const textSpan = btn.querySelector('span.font-medium');
      if (textSpan) {
        textSpan.textContent = text;
      }
      
      // Update button color
      if (reactionsData.user_reaction) {
        btn.classList.remove('text-gray-600');
        btn.classList.add('text-blue-600');
      } else {
        btn.classList.remove('text-blue-600');
        btn.classList.add('text-gray-600');
      }
    }
    
    // Update summary
    if (summary) {
      let html = '';
      if (reactionsData.top_reactions && reactionsData.top_reactions.length > 0) {
        reactionsData.top_reactions.forEach(rt => {
          html += `<span class="reaction-icon-small text-lg">${getReactionEmoji(rt)}</span>`;
        });
        html += `<span class="reactions-total ml-1">${reactionsData.total_count}</span>`;
      }
      summary.innerHTML = html;
    }
    
    // Update comments count if present
    const commentsCountEl = micropost.querySelector('.comments-count');
    if (commentsCountEl && reactionsData.comments_count !== undefined) {
      commentsCountEl.textContent = `${reactionsData.comments_count} ${reactionsData.comments_count === 1 ? 'comment' : 'comments'}`;
    }
  }
}

function getReactionEmoji(type) {
  const emojis = {
    'like': '👍',
    'love': '❤️',
    'haha': '😆',
    'wow': '😮',
    'sad': '😢',
    'angry': '😠'
  };
  return emojis[type] || '👍';
}

// ========== COMMENTS ==========
function initComments() {
  // Toggle comments section
  document.querySelectorAll('.btn-comment').forEach(btn => {
    btn.addEventListener('click', toggleComments);
  });
  
  // Comment form submission
  document.querySelectorAll('.comment-form').forEach(form => {
    form.addEventListener('submit', handleCommentSubmit);
  });
  
  // Reply buttons
  document.querySelectorAll('.btn-reply').forEach(btn => {
    btn.addEventListener('click', handleReplyClick);
  });
  
  // Edit comment
  document.querySelectorAll('.btn-edit-comment').forEach(btn => {
    btn.addEventListener('click', handleEditComment);
  });

  // Delete comment
  document.querySelectorAll('.btn-delete-comment').forEach(btn => {
    btn.addEventListener('click', handleDeleteComment);
  });
}

async function toggleComments(e) {
  e.preventDefault();
  e.stopPropagation();
  
  const micropostId = e.currentTarget.dataset.micropostId;
  const container = document.querySelector(`.comments-container[data-micropost-id="${micropostId}"]`);
  
  if (!container) return;
  
  if (container.style.display === 'none') {
    container.style.display = 'block';
    if (!container.dataset.loaded) {
      await loadComments(micropostId, container);
      container.dataset.loaded = 'true';
    }
  } else {
    container.style.display = 'none';
  }
}

async function loadComments(micropostId, container) {
  try {
    const response = await fetch(`/microposts/${micropostId}/comments`, {
      headers: { 'Accept': 'application/json' }
    });
    
    const data = await response.json();
    if (data.success) {
      renderComments(container, data.comments, micropostId);
    }
  } catch (error) {
    console.error('Error loading comments:', error);
    container.innerHTML = '<p class="text-muted">Failed to load comments</p>';
  }
}

function renderComments(container, comments, micropostId) {
  let html = `
    <div class="comments-section">
      <form class="comment-form" data-micropost-id="${micropostId}">
        <input type="hidden" name="parent_id" class="parent-id-field" value="">
        <div class="comment-input-wrapper">
          <textarea name="content" class="comment-input" placeholder="Write a comment..." rows="1" required></textarea>
          <button type="submit" class="btn btn-primary btn-sm">Post</button>
        </div>
      </form>
      <ul class="comments-list">
        ${renderNestedComments(comments, micropostId)}
      </ul>
    </div>
  `;
  
  container.innerHTML = html;
  
  // Reinitialize event handlers
  container.querySelector('.comment-form').addEventListener('submit', handleCommentSubmit);
  container.querySelectorAll('.btn-reply').forEach(btn => {
    btn.addEventListener('click', handleReplyClick);
  });
  container.querySelectorAll('.btn-edit-comment').forEach(btn => {
    btn.addEventListener('click', handleEditComment);
  });
  container.querySelectorAll('.btn-delete-comment').forEach(btn => {
    btn.addEventListener('click', handleDeleteComment);
  });
  
  // Init comment reactions
  initCommentReactions(container);
}

function initCommentReactions(container) {
  container.querySelectorAll('.comment-reaction-wrapper').forEach(wrapper => {
    const picker = wrapper.querySelector('.comment-reaction-picker');
    if (!picker) return;
    
    if (wrapper.dataset.commentReactionInitialized) return;
    wrapper.dataset.commentReactionInitialized = 'true';

    let hideTimeout;
    wrapper.addEventListener('mouseenter', () => {
      clearTimeout(hideTimeout);
      picker.classList.remove('hidden');
    });
    wrapper.addEventListener('mouseleave', () => {
      hideTimeout = setTimeout(() => picker.classList.add('hidden'), 300);
    });
    picker.addEventListener('mouseenter', () => clearTimeout(hideTimeout));
    picker.addEventListener('mouseleave', () => {
      hideTimeout = setTimeout(() => picker.classList.add('hidden'), 300);
    });
  });

  container.querySelectorAll('.comment-reaction-option:not([data-comment-reaction-option-initialized])').forEach(btn => {
    btn.dataset.commentReactionOptionInitialized = 'true';
    btn.addEventListener('click', handleCommentReactionOption);
  });

  container.querySelectorAll('.btn-comment-reaction:not([data-comment-quick-reaction-initialized])').forEach(btn => {
    btn.dataset.commentQuickReactionInitialized = 'true';
    btn.addEventListener('click', handleCommentQuickReaction);
  });
}

function renderNestedComments(comments, micropostId) {
  if (!comments || comments.length === 0) return '';

  const currentUserId = document.body.dataset.currentUserId;

  return comments.map(comment => {
    const isOwner = currentUserId && parseInt(currentUserId) === comment.user.id;
    const topReactions = comment.top_reactions || [];

    return `
    <li class="comment-item ${comment.parent_id ? 'nested-reply' : ''}" data-comment-id="${comment.id}" data-parent-id="${comment.parent_id || ''}">
      <div class="comment-content">
        <div class="comment-body">
          <div class="comment-header">
            <a href="/users/${comment.user.id}" class="comment-author">${comment.user.name}</a>
            <span class="comment-time">${comment.time_ago} ago</span>
          </div>
          <div class="comment-text">${comment.content}</div>
          <div class="comment-actions">
            <div class="comment-reaction-wrapper">
              <button class="btn-comment-reaction btn-sm ${comment.user_reaction ? 'reacted' : ''}" data-comment-id="${comment.id}" data-current-reaction="${comment.user_reaction || ''}">
                <span class="reaction-icon">${comment.user_reaction ? getReactionEmoji(comment.user_reaction) : '👍'}</span>
                <span class="reaction-text">${comment.user_reaction ? comment.user_reaction.charAt(0).toUpperCase() + comment.user_reaction.slice(1) : 'Like'}</span>
              </button>
              <div class="comment-reaction-picker hidden" data-comment-id="${comment.id}" style="flex-direction: row !important;">
                <button class="comment-reaction-option" data-reaction-type="like" data-comment-id="${comment.id}" title="Like" style="display: inline-block;">👍</button>
                <button class="comment-reaction-option" data-reaction-type="love" data-comment-id="${comment.id}" title="Love" style="display: inline-block;">❤️</button>
                <button class="comment-reaction-option" data-reaction-type="haha" data-comment-id="${comment.id}" title="Haha" style="display: inline-block;">😆</button>
                <button class="comment-reaction-option" data-reaction-type="wow" data-comment-id="${comment.id}" title="Wow" style="display: inline-block;">😮</button>
                <button class="comment-reaction-option" data-reaction-type="sad" data-comment-id="${comment.id}" title="Sad" style="display: inline-block;">😢</button>
                <button class="comment-reaction-option" data-reaction-type="angry" data-comment-id="${comment.id}" title="Angry" style="display: inline-block;">😠</button>
              </div>
            </div>
            ${comment.reactions_count > 0 ? `
              <div class="comment-reactions-display">
                ${topReactions.map(rt => `<span class="reaction-icon-tiny">${getReactionEmoji(rt)}</span>`).join('')}
                <span class="reaction-count">${comment.reactions_count}</span>
              </div>
            ` : ''}
            <button class="btn-reply btn-sm" data-comment-id="${comment.id}" data-micropost-id="${micropostId}">Reply</button>
            ${isOwner ? `
              <button class="btn-edit-comment btn-sm" data-comment-id="${comment.id}" data-micropost-id="${micropostId}">Edit</button>
              <button class="btn-delete-comment btn-sm text-danger" data-comment-id="${comment.id}" data-micropost-id="${micropostId}">Delete</button>
            ` : ''}
          </div>
        </div>
      </div>
      ${comment.replies ? `<ul class="comment-replies">${renderNestedComments(comment.replies, micropostId)}</ul>` : ''}
    </li>
  `;
  }).join('');
}

async function handleCommentSubmit(e) {
  e.preventDefault();
  e.stopPropagation();
  
  const form = e.currentTarget;
  const micropostId = form.dataset.micropostId;
  const content = form.querySelector('.comment-input').value.trim();
  const parentId = form.querySelector('.parent-id-field')?.value || null;
  
  if (!content) return;
  
  try {
    const response = await fetch(`/microposts/${micropostId}/comments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ comment: { content, parent_id: parentId } })
    });
    
    const data = await response.json();
    if (data.success) {
      // Reset form
      form.querySelector('.comment-input').value = '';
      form.querySelector('.parent-id-field').value = '';
      
      // Add new comment to list
      const list = form.closest('.comments-section').querySelector('.comments-list');
      if (parentId) {
        const parentComment = list.querySelector(`[data-comment-id="${parentId}"]`);
        let replies = parentComment.querySelector('.comment-replies');
        if (!replies) {
          replies = document.createElement('ul');
          replies.className = 'comment-replies';
          parentComment.appendChild(replies);
        }
        replies.insertAdjacentHTML('beforeend', renderNestedComments([data.comment], micropostId));
      } else {
        list.insertAdjacentHTML('beforeend', renderNestedComments([data.comment], micropostId));
      }
      
      // Update count
      updateCommentCount(micropostId, data.total_count);
      
      // Reinit handlers
      initComments();
      initReactions();
    }
  } catch (error) {
    console.error('Error posting comment:', error);
  }
}

function handleReplyClick(e) {
  e.preventDefault();
  e.stopPropagation();
  
  const commentId = e.currentTarget.dataset.commentId;
  const micropostId = e.currentTarget.dataset.micropostId;
  const container = document.querySelector(`.comments-container[data-micropost-id="${micropostId}"]`);
  const form = container.querySelector('.comment-form');
  
  if (form) {
    form.querySelector('.parent-id-field').value = commentId;
    form.querySelector('.comment-input').focus();
    form.querySelector('.comment-input').placeholder = 'Write a reply...';
  }
}

async function handleEditComment(e) {
  e.preventDefault();
  e.stopPropagation();

  const editBtn = e.currentTarget; // Save reference
  const commentId = editBtn.dataset.commentId;
  const micropostId = editBtn.dataset.micropostId;
  const commentEl = editBtn.closest('.comment-item');
  const commentTextEl = commentEl.querySelector('.comment-text');
  const commentActionsEl = commentEl.querySelector('.comment-actions');
  const currentContent = commentTextEl.textContent.trim();

  // Create inline edit form
  const editForm = document.createElement('div');
  editForm.className = 'comment-edit-form';
  editForm.innerHTML = `
    <textarea class="form-control mb-2" rows="2">${currentContent}</textarea>
    <button class="btn btn-sm btn-primary save-comment">Save</button>
    <button class="btn btn-sm btn-secondary cancel-comment">Cancel</button>
  `;

  // Replace comment text with edit form
  commentTextEl.style.display = 'none';
  commentTextEl.after(editForm);
  commentActionsEl.style.display = 'none'; // Hide all action buttons

  // Handle cancel
  editForm.querySelector('.cancel-comment').addEventListener('click', () => {
    editForm.remove();
    commentTextEl.style.display = '';
    commentActionsEl.style.display = '';
  });

  // Handle save
  editForm.querySelector('.save-comment').addEventListener('click', async () => {
    const newContent = editForm.querySelector('textarea').value.trim();
    if (!newContent) {
      alert('Comment cannot be empty');
      return;
    }

    try {
      const response = await fetch(`/microposts/${micropostId}/comments/${commentId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ comment: { content: newContent } })
      });

      const data = await response.json();
      
      if (response.ok && data.success) {
        commentTextEl.textContent = newContent;
        editForm.remove();
        commentTextEl.style.display = '';
        commentActionsEl.style.display = '';
      } else {
        alert('Failed to update: ' + (data.errors || []).join(', '));
      }
    } catch (error) {
      console.error('Error updating comment:', error);
      alert('Error updating comment');
    }
  });
}

async function handleDeleteComment(e) {
  e.preventDefault();
  e.stopPropagation();

  if (!confirm('Delete this comment?')) return;

  const commentId = e.currentTarget.dataset.commentId;
  const micropostId = e.currentTarget.dataset.micropostId;
  const commentEl = e.currentTarget.closest('.comment-item');

  try {
    const response = await fetch(`/microposts/${micropostId}/comments/${commentId}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    });

    const data = await response.json();
    if (data.success) {
      commentEl.remove();
      updateCommentCount(micropostId, data.total_count);
    }
  } catch (error) {
    console.error('Error deleting comment:', error);
  }
}

function updateCommentCount(micropostId, count) {
  const micropost = document.getElementById(`micropost-${micropostId}`);
  if (!micropost) return;
  
  const stat = micropost.querySelector('.comments-stat');
  if (stat) {
    stat.textContent = count > 0 ? `${count} comments` : '';
  }
}

// ========== SHARES ==========
function initShares() {
  document.querySelectorAll('.btn-share').forEach(btn => {
    btn.addEventListener('click', handleShare);
  });
}

async function handleShare(e) {
  e.preventDefault();
  e.stopPropagation();
  
  const btn = e.currentTarget;
  const micropostId = btn.dataset.micropostId;
  const isShared = btn.classList.contains('shared');
  
  if (isShared) {
    // Unshare
    if (!confirm('Remove share from your profile?')) return;
    
    try {
      const response = await fetch(`/microposts/${micropostId}/shares/destroy`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      });
      
      const data = await response.json();
      if (data.success) {
        updateShareUI(micropostId, data.shares_count, false);
        // Remove share from feed if visible
        const shareEl = document.querySelector(`.share-item[data-original-post="${micropostId}"]`);
        if (shareEl) shareEl.remove();
      }
    } catch (error) {
      console.error('Error unsharing:', error);
    }
  } else {
    // Show share modal
    showShareModal(micropostId);
  }
}

function showShareModal(micropostId) {
  const micropost = document.getElementById(`micropost-${micropostId}`);
  if (!micropost) return;
  
  const content = micropost.querySelector('.content')?.textContent || '';
  const userName = micropost.querySelector('.user a')?.textContent || '';
  const imageEl = micropost.querySelector('.micropost-image img');
  const imageHtml = imageEl ? `<img src="${imageEl.src}" class="img-fluid">` : '';
  
  const modal = document.createElement('div');
  modal.className = 'share-modal-overlay';
  modal.innerHTML = `
    <div class="share-modal">
      <div class="share-modal-header">
        <h3>Share Post</h3>
        <button class="share-modal-close">&times;</button>
      </div>
      <div class="share-modal-body">
        <textarea class="share-caption-input" placeholder="Say something about this..." rows="3"></textarea>
        <div class="share-preview">
          <div class="shared-post-header" style="padding: 12px;">
            <strong>${userName}</strong>
          </div>
          <div class="shared-post-content" style="padding: 0 12px 12px;">
            ${content}
            ${imageHtml ? `<div class="shared-post-image">${imageHtml}</div>` : ''}
          </div>
        </div>
      </div>
      <div class="share-modal-footer">
        <button class="btn-share-submit" data-micropost-id="${micropostId}">Share Now</button>
      </div>
    </div>
  `;
  
  document.body.appendChild(modal);
  
  // Close modal
  modal.querySelector('.share-modal-close').addEventListener('click', () => modal.remove());
  modal.addEventListener('click', (e) => {
    if (e.target === modal) modal.remove();
  });
  
  // Submit share
  modal.querySelector('.btn-share-submit').addEventListener('click', async () => {
    const caption = modal.querySelector('.share-caption-input').value.trim();
    await submitShare(micropostId, caption);
    modal.remove();
  });
}

async function submitShare(micropostId, caption) {
  try {
    const response = await fetch(`/microposts/${micropostId}/share`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ content: caption })
    });
    
    const data = await response.json();
    if (data.success) {
      // Redirect to user profile and scroll to new shared post
      window.location.href = data.redirect_url || `/users/${data.micropost.user.id}#micropost-${data.micropost.id}`;
    } else {
      alert('Failed to share: ' + (data.errors || []).join(', '));
    }
  } catch (error) {
    console.error('Error sharing:', error);
    alert('Error sharing post');
  }
}

function updateShareUI(micropostId, count, shared) {
  const micropost = document.getElementById(`micropost-${micropostId}`);
  if (!micropost) return;
  
  const btn = micropost.querySelector('.btn-share');
  const stat = micropost.querySelector('.shares-stat');
  
  if (btn) {
    btn.classList.toggle('shared', shared);
    btn.innerHTML = shared ? '✓ Shared' : '↗️ Share';
  }
  
  if (stat) {
    stat.textContent = count > 0 ? `${count} shares` : '';
  } else if (count > 0) {
    const statsContainer = micropost.querySelector('.engagement-stats');
    if (statsContainer) {
      statsContainer.insertAdjacentHTML('beforeend', `<span class="shares-stat">${count} shares</span>`);
    }
  }
}

// Export for use in other modules
window.SocialFeatures = {
  initSocialFeatures,
  updateReactionUI,
  updateCommentCount
};
