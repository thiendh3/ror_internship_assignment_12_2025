require 'rsolr'

class SolrClient
  def self.connection
    @connection ||= RSolr.connect url: ENV.fetch(
      'SOLR_URL',
      'http://solr:8983/solr/micropost_core'
    )
  end

  def self.add(doc)
    connection.add(doc)
    connection.commit
  end

  def self.delete_by_id(id)
    connection.delete_by_id(id)
  end

  def self.commit
    connection.commit
  end

  def self.get(path, params:)
    connection.get(path, params: params)
  end
end
