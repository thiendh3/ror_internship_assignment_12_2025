require 'rsolr'

class MicropostAutocomplete
  def self.call(keyword)
    return { 'response' => { 'docs' => [] } } if keyword.blank?

    tokens = keyword.to_s.strip.split(/\s+/).compact_blank
    escaped_terms = tokens.map { |t| "content:*#{RSolr.solr_escape(t)}*" }
    query = escaped_terms.any? ? escaped_terms.join(' AND ') : '*:*'

    SolrClient.connection.get 'select', params: {
      q: query,
      fl: 'id,content',
      rows: 5,
      sort: 'created_at desc'
    }
  end
end
