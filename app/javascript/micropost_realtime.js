// Real-time micropost updates via WebSocket
import consumer from "actioncable_consumer"

let micropostSubscription = null;
let newPostsCount = 0;
let newPostsQueue = [];

function initializeMicropostRealtime() {
    // Only initialize on feed page (root path)
    const feedContainer = document.querySelector('.microposts');
    if (!feedContainer) return;

    // Create subscription
    if (!micropostSubscription) {
        micropostSubscription = consumer.subscriptions.create("MicropostChannel", {
            connected() {
                console.log("Connected to MicropostChannel");
            },

            disconnected() {
                console.log("Disconnected from MicropostChannel");
            },

            received(data) {
                if (data.type === "reaction") {
                    updateReactionCountsRealtime(data);
                    return;
                }

                console.log("Received new micropost:", data);

                // Don't show notification for own posts
                const currentUserId = getCurrentUserId();
                if (currentUserId && data.user && data.user.id === currentUserId) {
                    // Add directly to feed for own posts
                    prependMicropostToFeed(data.html);
                    return;
                }

                // Queue the new post
                newPostsQueue.unshift(data);
                newPostsCount++;

                // Update notification banner
                updateNewPostsBanner();
            }
        });
    }
}

function getCurrentUserId() {
    // Try to get from feed container or other elements
    const userIdElement = document.querySelector('[data-current-user-id]');
    return userIdElement ? parseInt(userIdElement.dataset.currentUserId) : null;
}

function updateNewPostsBanner() {
    let banner = document.querySelector('.new-posts-banner');

    if (!banner) {
        banner = document.createElement('div');
        banner.className = 'new-posts-banner';
        banner.style.cssText = `
            position: fixed;
            top: 60px;
            left: 50%;
            transform: translateX(-50%);
            background: #1da1f2;
            color: white;
            padding: 12px 24px;
            border-radius: 24px;
            box-shadow: 0 4px 12px rgba(29, 161, 242, 0.3);
            cursor: pointer;
            z-index: 1000;
            font-weight: 600;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 8px;
            animation: slideDown 0.3s ease;
            transition: all 0.2s;
        `;

        banner.addEventListener('click', loadNewPosts);

        const feedContainer = document.querySelector('.microposts');
        if (feedContainer && feedContainer.parentElement) {
            feedContainer.parentElement.insertBefore(banner, feedContainer);
        }
    }

    banner.innerHTML = `
        <i class="glyphicon glyphicon-refresh"></i>
        <span>${newPostsCount} new ${newPostsCount === 1 ? 'post' : 'posts'}</span>
    `;

    banner.style.display = 'flex';

    // Add hover effect
    banner.onmouseenter = function () {
        this.style.background = '#1a8cd8';
        this.style.transform = 'translateX(-50%) scale(1.05)';
    };
    banner.onmouseleave = function () {
        this.style.background = '#1da1f2';
        this.style.transform = 'translateX(-50%) scale(1)';
    };
}

function updateReactionCountsRealtime(data) {
    const { micropost_id: micropostId, reaction_counts: reactionCounts, likes_count: likesCount } = data;
    if (!micropostId) return;

    const summary = document.querySelector(
        `.reaction-summary[data-micropost-id="${micropostId}"]`
    );
    if (!summary) return;

    if (reactionCounts) {
        toggleReactionIcon(summary, "like", reactionCounts.like || 0);
        toggleReactionIcon(summary, "love", reactionCounts.love || 0);
        toggleReactionIcon(summary, "haha", reactionCounts.haha || 0);
    }

    const totalEl = summary.querySelector('[data-reaction-total]');
    if (totalEl && typeof likesCount !== "undefined") totalEl.textContent = likesCount;
}

function toggleReactionIcon(summary, type, count) {
    const icon = summary.querySelector(`[data-reaction-type="${type}"]`);
    if (!icon) return;

    icon.style.display = count > 0 ? "inline-flex" : "none";
}

function loadNewPosts() {
    const feedContainer = document.querySelector('.microposts');
    if (!feedContainer) return;

    // Add all queued posts to feed
    newPostsQueue.reverse().forEach(postData => {
        prependMicropostToFeed(postData.html);
    });

    // Reset counter and queue
    newPostsCount = 0;
    newPostsQueue = [];

    // Hide banner with animation
    const banner = document.querySelector('.new-posts-banner');
    if (banner) {
        banner.style.animation = 'slideUp 0.3s ease';
        setTimeout(() => {
            banner.style.display = 'none';
        }, 300);
    }
}

function prependMicropostToFeed(html) {
    const feedContainer = document.querySelector('.microposts');
    if (!feedContainer) return;

    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = html;
    const newPost = tempDiv.firstChild;

    // Add animation class
    newPost.style.animation = 'fadeInSlideDown 0.5s ease';

    feedContainer.insertBefore(newPost, feedContainer.firstChild);

    // Scroll to show new post
    newPost.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

// Add CSS animations
function addRealtimeStyles() {
    if (document.querySelector('#realtime-styles')) return;

    const style = document.createElement('style');
    style.id = 'realtime-styles';
    style.textContent = `
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateX(-50%) translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateX(-50%) translateY(0);
            }
        }
        
        @keyframes slideUp {
            from {
                opacity: 1;
                transform: translateX(-50%) translateY(0);
            }
            to {
                opacity: 0;
                transform: translateX(-50%) translateY(-20px);
            }
        }
        
        @keyframes fadeInSlideDown {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
    `;
    document.head.appendChild(style);
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    addRealtimeStyles();
    initializeMicropostRealtime();
});
document.addEventListener('turbo:load', () => {
    addRealtimeStyles();
    initializeMicropostRealtime();
});

export { initializeMicropostRealtime };
