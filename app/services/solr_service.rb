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

    def search(query, page: 1, per_page: 30, is_admin: false, filter_type: 'all', following_ids: [], current_user_id: nil)
      start_row = (page.to_i - 1) * per_page.to_i

      safe_query = query.gsub(/[^a-zA-Z0-9\s@\.]/, '')
      safe_query = "*" if safe_query.blank?

      # 1. Build Filter Query (fq)
      fq_parts = []

      case filter_type
      when 'activated'
        fq_parts << 'active_boolean:true'
      when 'not_activated'
        fq_parts << 'active_boolean:false'
      when 'following'
        fq_parts << 'active_boolean:true' # Only show activated users in following
        if following_ids.empty?
          # If following no one, return empty immediately to save Solr trip
          return { ids: [], total: 0 }
        else
          fq_parts << "id:(#{following_ids.join(' OR ')})"
        end
      when 'not_following'
        fq_parts << 'active_boolean:true'
        # Exclude people I follow
        fq_parts << "-id:(#{following_ids.join(' OR ')})" if following_ids.any?
        # Exclude myself from "Not Following" suggestions
        fq_parts << "-id:#{current_user_id}" if current_user_id
      else # 'all' or unknown
        fq_parts << 'active_boolean:true'
      end

      # 2. Build Text Query (q)
      if safe_query == "*"
        final_query = "*:*"
      else
        text_fuzzy_clause = safe_query.length >= 3 ? " OR #{safe_query}~1" : ""
        
        text_fields = ["name_text^5", "bio_text"]
        text_fields << "email_text" if is_admin
        
        text_query = text_fields.map do |f| 
          field, boost = f.split('^')
          boost_suffix = boost ? "^#{boost}" : ""
          "#{field}:(#{safe_query}#{text_fuzzy_clause})#{boost_suffix}" 
        end.join(" OR ")

        ac_fields = ["name_ac^10", "bio_ac^2"]
        ac_fields << "email_ac^2" if is_admin

        ac_query = ac_fields.map do |f| 
          field, boost = f.split('^')
          boost_suffix = boost ? "^#{boost}" : ""
          "#{field}:#{safe_query}#{boost_suffix}" 
        end.join(" OR ")
        
        final_query = "(#{text_query}) OR (#{ac_query})"
      end

      response = connection.get "select", params: {
        q: final_query,
        defType: 'lucene', 
        fq: fq_parts, # RSolr handles array of fq by adding multiple fq params
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