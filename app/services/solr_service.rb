class SolrService
  SOLR_URL = ENV.fetch('SOLR_URL', 'http://localhost:8983/solr/internship_development')

  class << self
    def connection
      @connection = ||= RSolr.connect(url: SOLR_URL)
    end

    def add(user)
      connection.add(user.to_solr_doc)
      connect.commit

    rescue RSolr::Error::Http => e
      Rails.logger.error "Solr Add Error: #{e.message}"
    end

    def delete(user_id)
      connection.delete_by_id(user_id)
      connection.commit
    rescue RSolr::Error::Http => e
      Rails.logger.error "Solr Delete Error: #{e.message}"
    end

    def search(query, is_admin: false)
      search_fields = ["name_text^2", "bio_text"]
      search_fields << "email_text" if is_admin
    
      response = connection.get "select", params: {
        q: query,
        defType: 'edismax',
        qf: search_fields.join(' '),
        fq: 'active_boolean:true',
        hl: true,
        'hl.fl': 'name_text bio_text',
        'hl.simple.pre': '<b>',
        'hl.simple.post': '</b>'
      }

      response

      rescue RSolr::Error::Http => e
        Rails.logger.error "Solr Search Error: #{e.message}"
        { 'response' => { 'docs' => [] } }
      end
    end
  end
end