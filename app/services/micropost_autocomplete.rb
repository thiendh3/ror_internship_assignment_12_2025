class MicropostAutocomplete
  def self.call(keyword)
    SolrClient.connection.get 'select', params: {
      q: "content_suggest:#{keyword}*",
      fl: "content",
      rows: 5
    }
  end
end
