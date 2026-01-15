require 'rsolr'

class MicropostSearch
  SEARCH_FIELDS = %w[content_txt content].freeze

  def self.search(query:, user_id: nil, hashtag: nil, from: nil, to: nil)
    filter_queries = build_filter_queries(user_id: user_id, hashtag: hashtag, from: from, to: to)

    SolrClient.connection.get 'select', params: search_params(query, filter_queries)
  end

  def self.build_filter_queries(user_id:, hashtag:, from:, to:)
    filter_queries = []
    filter_queries << "user_id:#{RSolr.solr_escape(user_id.to_s)}" if user_id.present?
    filter_queries << build_hashtag_filter(hashtag) if hashtag.present?
    filter_queries << build_date_range_filter(from, to) if from.present? || to.present?
    filter_queries
  end

  def self.build_hashtag_filter(hashtag)
    tag = hashtag.to_s.delete_prefix('#').downcase
    "hashtags:#{RSolr.solr_escape(tag)}"
  end

  def self.build_date_range_filter(from, to)
    from_value = from.present? ? RSolr.solr_escape(from.to_s) : '*'
    to_value = to.present? ? RSolr.solr_escape(to.to_s) : '*'
    "created_at:[#{from_value} TO #{to_value}]"
  end

  def self.search_params(query, filter_queries)
    {
      q: build_content_query(query),
      fq: filter_queries,
      hl: true,
      'hl.fl': 'content',
      'hl.simple.pre': '<mark>',
      'hl.simple.post': '</mark>',
      rows: 1000,
      sort: 'created_at desc'
    }
  end

  def self.build_content_query(raw_query)
    return '*:*' if raw_query.blank?

    tokens = tokenize_query(raw_query)
    return '*:*' if tokens.empty?

    parts = tokens.map { |token| build_token_query(token) }.compact
    return '*:*' if parts.empty?

    parts.join(' AND ')
  end

  def self.tokenize_query(raw_query)
    raw_query.to_s.strip.split(/\s+/)
  end

  def self.build_token_query(token)
    cleaned = token.to_s.gsub(/[*~]/, '')
    escaped = RSolr.solr_escape(cleaned)
    return if escaped.blank?

    if cleaned.length < 3
      build_short_token_query(escaped)
    else
      build_long_token_query(escaped)
    end
  end

  def self.build_short_token_query(escaped)
    field_queries = SEARCH_FIELDS.map { |f| "#{f}:#{escaped}*" }
    "(#{field_queries.join(' OR ')})"
  end

  def self.build_long_token_query(escaped)
    field_queries = SEARCH_FIELDS.map { |f| "#{f}:(#{escaped}~1 OR #{escaped}*)" }
    "(#{field_queries.join(' OR ')})"
  end
end
