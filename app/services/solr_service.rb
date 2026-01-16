class SolrService
  SOLR_URL = ENV.fetch('SOLR_URL')

  class << self
    def connection
      @connection ||= RSolr.connect(url: SOLR_URL)
    end

    def add(record)
      connection.add(record.to_solr_doc)
      connection.commit
    rescue RSolr::Error::Http => e
      Rails.logger.error "Solr Add Error: #{e.message}"
    end

    def delete(id)
      connection.delete_by_id(id)
      connection.commit
    rescue RSolr::Error::Http => e
      Rails.logger.error "Solr Delete Error: #{e.message}"
    end

    def search(query: '*:*', page: 1, per_page: 30, **options)
      start_row = (page.to_i - 1) * per_page.to_i

      solr_params = {
        q: query,
        fq: options[:filter_query] || [],
        rows: per_page,
        start: start_row,
        defType: 'lucene'
      }

      solr_params[:bq]   = options[:boost_query] if options[:boost_query].present?
      solr_params[:sort] = options[:sort]        if options[:sort].present?

      perform_request(solr_params)
    end

    private

    def perform_request(params)
      response = connection.get 'select', params: params
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
