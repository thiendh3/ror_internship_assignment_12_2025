class MicropostSearch
  def self.search(q:, user_id: nil, hashtag: nil, from: nil, to: nil)
    fq = []

    fq << "user_id:#{user_id}" if user_id.present?
    fq << "hashtags:#{hashtag.downcase}" if hashtag.present?
    fq << "created_at:[#{from} TO #{to}]" if from && to

    SolrClient.connection.get 'select', params: {
      q: q.present? ? "content:(#{q})" : "*:*",
      fq: fq,
      hl: true,
      'hl.fl': 'content',
      'hl.simple.pre': '<mark>',
      'hl.simple.post': '</mark>',
      rows: 1000,
      sort: 'created_at desc'
    }
  end
end
