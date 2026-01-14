require 'rsolr'

class SolrClient
  def self.client
    @client ||= RSolr.connect url: ENV.fetch(
      'SOLR_URL',
      'http://solr:8983/solr/micropost_core'
    )
  end

  def self.add(doc)
    client.add(doc)
  end

  def self.delete_by_id(id)
    client.delete_by_id(id)
  end

  def self.commit
    client.commit
  end

  def self.get(path, params:)
    client.get(path, params: params)
  end
end
