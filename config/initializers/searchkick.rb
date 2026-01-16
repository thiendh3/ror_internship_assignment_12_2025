# rubocop:disable Style/FrozenStringLiteralComment
# Searchkick configuration for Elasticsearch
Searchkick.client_options = {
  url: ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200'),
  transport_options: {
    request: { timeout: 30 }
  }
}

# Configure search options
Searchkick.search_method_name = :search
Searchkick.timeout = 30
# rubocop:enable Style/FrozenStringLiteralComment
