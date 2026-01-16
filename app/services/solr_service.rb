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

    # return { ids: [...], total: N }
    def search(q: '*:*', fq: [], bq: nil, sort: nil, page: 1, per_page: 30)
      start_row = (page.to_i - 1) * per_page.to_i

      solr_params = {
        q: q,
        fq: fq,
        rows: per_page,
        start: start_row,
        defType: 'lucene'
      }
      solr_params[:bq] = bq if bq.present?
      solr_params[:sort] = sort if sort.present?

      response = connection.get 'select', params: solr_params

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
