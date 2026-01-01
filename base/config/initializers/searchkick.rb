# rubocop:disable Style/FrozenStringLiteralComment
# Searchkick configuration for Solr
Searchkick.client_options = {
  url: ENV.fetch('SOLR_URL', 'http://localhost:8983/solr'),
  read_timeout: 10,
  open_timeout: 10
}

# Configure search options
Searchkick.search_method_name = :search
Searchkick.timeout = 10
Searchkick.batch_size = 1000

# Enable highlighting by default
Searchkick.highlight = true

# Enable suggestions
Searchkick.suggest = true

# Log search queries in development
Searchkick.logger = Rails.logger if Rails.env.development?
# rubocop:enable Style/FrozenStringLiteralComment
