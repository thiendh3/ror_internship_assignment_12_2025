require 'rsolr'

class MicropostSearch
  SEARCH_FIELDS = %w[content_txt content].freeze

  def self.search(q:, user_id: nil, hashtag: nil, from: nil, to: nil)
    fq = []

    fq << "user_id:#{RSolr.solr_escape(user_id.to_s)}" if user_id.present?

    if hashtag.present?
      tag = hashtag.to_s.delete_prefix('#').downcase
      fq << "hashtags:#{RSolr.solr_escape(tag)}"
    end

    if from.present? && to.present?
      fq << "created_at:[#{RSolr.solr_escape(from.to_s)} TO #{RSolr.solr_escape(to.to_s)}]"
    elsif from.present?
      fq << "created_at:[#{RSolr.solr_escape(from.to_s)} TO *]"
    elsif to.present?
      fq << "created_at:[* TO #{RSolr.solr_escape(to.to_s)}]"
    end

    SolrClient.connection.get 'select', params: {
      q: build_content_query(q),
      fq: fq,
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

    tokens = raw_query.to_s.strip.split(/\s+/)
    return '*:*' if tokens.empty?

    parts = tokens.map do |token|
      # Remove user-provided fuzzy/wildcard markers to avoid accidental heavy queries.
      cleaned = token.to_s.gsub(/[*~]/, '')
      escaped = RSolr.solr_escape(cleaned)
      next if escaped.blank?

      if cleaned.length < 3
        SEARCH_FIELDS.map { |f| "#{f}:#{escaped}*" }.join(' OR ').then { |q| "(#{q})" }
      else
        SEARCH_FIELDS.map { |f| "#{f}:(#{escaped}~1 OR #{escaped}*)" }.join(' OR ').then { |q| "(#{q})" }
      end
    end.compact

    return '*:*' if parts.empty?

    parts.join(' AND ')
  end
end
