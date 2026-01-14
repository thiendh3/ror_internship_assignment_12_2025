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

    def search(query, page: 1, per_page: 20, is_admin: false)
      start_row = (page.to_i - 1) * per_page.to_i

      safe_query = query.gsub(/[^a-zA-Z0-9\s@\.]/, '')
      return { ids: [], total: 0 } if safe_query.blank?

      text_fields = ["name_text^5", "bio_text"]
      text_fields << "email_text" if is_admin
      
      text_query = text_fields.map do |f| 
        field, boost = f.split('^')
        boost_suffix = boost ? "^#{boost}" : ""
        "#{field}:(#{safe_query} OR #{safe_query}~1)#{boost_suffix}" 
      end.join(" OR ")

      ac_fields = ["name_ac^2", "bio_ac"]
      ac_fields << "email_ac" if is_admin

      ac_query = ac_fields.map do |f| 
        field, boost = f.split('^')
        boost_suffix = boost ? "^#{boost}" : ""
        "#{field}:#{safe_query}#{boost_suffix}" 
      end.join(" OR ")
      
      final_query = "(#{text_query}) OR (#{ac_query})"

      response = connection.get "select", params: {
        q: final_query,
        defType: 'lucene', 
        fq: 'active_boolean:true',

        hl: true,
        'hl.fl': 'name_ac bio_ac email_ac', 
        'hl.simple.pre': '<strong class="text-primary">', 
        'hl.simple.post': '</strong>',
        'hl.method': 'original', 
        'hl.preserveMulti': true, 
        
        rows: per_page,
        start: start_row
      }

      puts response[:docs]

      {
        ids: response.dig('response', 'docs')&.map { |d| d['id'] } || [],
        total: response.dig('response', 'numFound') || 0,
        highlighting: response['highlighting'] || {}
      }

    rescue RSolr::Error::Http => e
      Rails.logger.error "Solr Search Error: #{e.message}"
      { ids: [], total: 0, highlighting: {} }
    end
  end
end