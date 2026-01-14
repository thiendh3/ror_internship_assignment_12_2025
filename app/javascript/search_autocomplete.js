// Search autocomplete functionality
function initializeSearchAutocomplete() {
    const searchInput = document.getElementById('search-query');
    const autocompleteResults = document.getElementById('autocomplete-results');

    if (!searchInput || !autocompleteResults) return;

    let debounceTimer;

    searchInput.addEventListener('input', function () {
        const query = this.value.trim();

        // Clear previous timer
        clearTimeout(debounceTimer);

        // Hide dropdown if query is too short
        if (query.length < 2) {
            autocompleteResults.classList.remove('show');
            autocompleteResults.innerHTML = '';
            return;
        }

        // Debounce the API call (wait 300ms after user stops typing)
        debounceTimer = setTimeout(function () {
            fetchAutocomplete(query);
        }, 300);
    });

    function fetchAutocomplete(query) {
        fetch(`/search/autocomplete?q=${encodeURIComponent(query)}`, {
            headers: {
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
        })
            .then(response => response.json())
            .then(data => {
                displayAutocompleteResults(data);
            })
            .catch(error => {
                console.error('Autocomplete error:', error);
            });
    }

    function displayAutocompleteResults(results) {
        if (!results || results.length === 0) {
            autocompleteResults.classList.remove('show');
            autocompleteResults.innerHTML = '';
            return;
        }

        let html = '';
        results.forEach(function (item) {
            const content = item.content || '';
            const truncated = content.length > 100 ? content.substring(0, 100) + '...' : content;
            html += `<div class="autocomplete-item" data-content="${escapeHtml(content)}">${escapeHtml(truncated)}</div>`;
        });

        autocompleteResults.innerHTML = html;
        autocompleteResults.classList.add('show');

        // Add click handlers to autocomplete items
        const items = autocompleteResults.querySelectorAll('.autocomplete-item');
        items.forEach(function (item) {
            item.addEventListener('click', function () {
                const content = this.getAttribute('data-content');
                searchInput.value = content;
                autocompleteResults.classList.remove('show');
                autocompleteResults.innerHTML = '';
            });
        });
    }

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // Close autocomplete when clicking outside
    document.addEventListener('click', function (event) {
        if (!searchInput.contains(event.target) && !autocompleteResults.contains(event.target)) {
            autocompleteResults.classList.remove('show');
        }
    });

    // Handle keyboard navigation
    searchInput.addEventListener('keydown', function (event) {
        const items = autocompleteResults.querySelectorAll('.autocomplete-item');
        const activeItem = autocompleteResults.querySelector('.autocomplete-item.active');

        if (event.key === 'ArrowDown') {
            event.preventDefault();
            if (!activeItem) {
                items[0]?.classList.add('active');
            } else {
                activeItem.classList.remove('active');
                const next = activeItem.nextElementSibling;
                if (next) {
                    next.classList.add('active');
                } else {
                    items[0]?.classList.add('active');
                }
            }
        } else if (event.key === 'ArrowUp') {
            event.preventDefault();
            if (activeItem) {
                activeItem.classList.remove('active');
                const prev = activeItem.previousElementSibling;
                if (prev) {
                    prev.classList.add('active');
                } else {
                    items[items.length - 1]?.classList.add('active');
                }
            }
        } else if (event.key === 'Enter') {
            if (activeItem) {
                event.preventDefault();
                activeItem.click();
            }
        } else if (event.key === 'Escape') {
            autocompleteResults.classList.remove('show');
            autocompleteResults.innerHTML = '';
        }
    });
}

// Initialize on page load and Turbo navigation
document.addEventListener('DOMContentLoaded', initializeSearchAutocomplete);
document.addEventListener('turbo:load', initializeSearchAutocomplete);
document.addEventListener('turbo:render', initializeSearchAutocomplete);
