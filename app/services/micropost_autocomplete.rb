class MicropostAutocomplete
  def self.call(keyword)
    return { 'response' => { 'docs' => [] } } if keyword.blank?
    
    SolrClient.connection.get 'select', params: {
      q: "content:*#{keyword}*",
      fl: "id,content",
      rows: 5,
      sort: 'created_at desc'
    }
  end
end
