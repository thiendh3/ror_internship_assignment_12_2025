// Share micropost functionality
document.addEventListener('DOMContentLoaded', initializeShare);
document.addEventListener('turbo:load', initializeShare);
document.addEventListener('turbo:render', initializeShare);

function initializeShare() {
    document.querySelectorAll('.share-btn').forEach(btn => {
        if (btn.dataset.shareBound) return;
        btn.dataset.shareBound = 'true';

        btn.addEventListener('click', handleShare);
    });
}

function handleShare(e) {
    e.preventDefault();

    const micropostId = this.dataset.micropostId;
    const micropostUrl = `${window.location.origin}/microposts/${micropostId}`;

    // Use Clipboard API to copy link
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(micropostUrl)
            .then(() => {
                showShareToast('Link copied to clipboard!');
            })
            .catch(err => {
                console.error('Failed to copy link:', err);
                fallbackCopyText(micropostUrl);
            });
    } else {
        // Fallback for older browsers
        fallbackCopyText(micropostUrl);
    }
}

function fallbackCopyText(text) {
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();

    try {
        document.execCommand('copy');
        showShareToast('Link copied to clipboard!');
    } catch (err) {
        console.error('Fallback copy failed:', err);
        showShareToast('Failed to copy link', 'error');
    }

    document.body.removeChild(textarea);
}

function showShareToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `share-toast ${type}`;
    toast.innerHTML = `
        <i class="glyphicon glyphicon-${type === 'success' ? 'ok' : 'exclamation-sign'}"></i>
        <span>${message}</span>
    `;

    const styles = type === 'success'
        ? 'background: #17bf63; color: white;'
        : 'background: #e0245e; color: white;';

    toast.style.cssText = `
        position: fixed;
        bottom: 30px;
        right: 30px;
        ${styles}
        padding: 12px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        display: flex;
        align-items: center;
        gap: 10px;
        z-index: 10000;
        font-size: 14px;
        font-weight: 500;
        animation: slideInUp 0.3s ease;
    `;

    document.body.appendChild(toast);

    setTimeout(() => {
        toast.style.animation = 'slideOutDown 0.3s ease';
        setTimeout(() => toast.remove(), 300);
    }, 2500);
}

// Add CSS animations if not already present
if (!document.querySelector('#share-animations')) {
    const style = document.createElement('style');
    style.id = 'share-animations';
    style.textContent = `
        @keyframes slideInUp {
            from {
                transform: translateY(100px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }
        
        @keyframes slideOutDown {
            from {
                transform: translateY(0);
                opacity: 1;
            }
            to {
                transform: translateY(100px);
                opacity: 0;
            }
        }
    `;
    document.head.appendChild(style);
}

export { initializeShare };
