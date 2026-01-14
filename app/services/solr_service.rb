class SolrService
  SOLR_URL = ENV.fetch('SOLR_URL')

  class << self
    def connection
      puts SOLR_URL
      @connection ||= RSolr.connect(url: SOLR_URL)
    end

    def add(user)
      connection.add(user.to_solr_doc)
      connection.commit
    rescue RSolr::Error::Http => e
      Rails.logger.error "Solr Add Error: #{e.message}"
    end

    def delete(user_id)
      connection.delete_by_id(user_id)
      connection.commit
    rescue RSolr::Error::Http => e
      Rails.logger.error "Solr Delete Error: #{e.message}"
    end

    def search(query, page: 1, per_page: 30, is_admin: false, filter_type: 'all', following_ids: [], current_user_id: nil, search_field: 'name')
      start_row = (page.to_i - 1) * per_page.to_i

      safe_query = query.gsub(/[^a-zA-Z0-9\s@\.]/, '')
      safe_query = "*" if safe_query.blank?

      # 1. Build Filter Query (fq) - (Unchanged)
      fq_parts = []
      case filter_type
      when 'activated'
        fq_parts << 'active_boolean:true'
      when 'not_activated'
        fq_parts << 'active_boolean:false'
      when 'following'
        fq_parts << 'active_boolean:true'
        return { ids: [], total: 0 } if following_ids.empty?
        fq_parts << "id:(#{following_ids.join(' OR ')})"
      when 'not_following'
        fq_parts << 'active_boolean:true'
        fq_parts << "-id:(#{following_ids.join(' OR ')})" if following_ids.any?
        fq_parts << "-id:#{current_user_id}" if current_user_id
      else
        fq_parts << 'active_boolean:true'
      end

      # 2. Build Text Query (q) - UPDATED
      if safe_query == "*"
        final_query = "*:*"
      else
        # Determine fields based on admin choice
        if is_admin && search_field == 'email'
          # Search Email
          text_field = "email_text"
          ac_field   = "email_ac^2"
        else
          # Default: Search Name (Bio is excluded)
          text_field = "name_text^5"
          ac_field   = "name_ac^10"
        end

        # Construct fuzzy clause
        text_fuzzy_clause = safe_query.length >= 3 ? " OR #{safe_query}~1" : ""

        # Build specific field queries
        # Split on ^ to handle boosts correctly if present
        tf_name, tf_boost = text_field.split('^')
        tf_boost_str = tf_boost ? "^#{tf_boost}" : ""
        text_part = "#{tf_name}:(#{safe_query}#{text_fuzzy_clause})#{tf_boost_str}"

        ac_name, ac_boost = ac_field.split('^')
        ac_boost_str = ac_boost ? "^#{ac_boost}" : ""
        ac_part = "#{ac_name}:#{safe_query}#{ac_boost_str}"

        final_query = "(#{text_part}) OR (#{ac_part})"
      end

      response = connection.get "select", params: {
        q: final_query,
        defType: 'lucene',
        fq: fq_parts,
        rows: per_page,
        start: start_row
      }

      {
        ids: response.dig('response', 'docs')&.map { |d| d['id'] } || [],
        total: response.dig('response', 'numFound') || 0
      }

    rescue RSolr::Error::Http => e
      Rails.logger.error "Solr Search Error: #{e.message}"
      { ids: [], total: 0 }
    end
  end
end