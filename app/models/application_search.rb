require 'ostruct'

class ApplicationSearch
  include ActiveModel::Model

  attr_reader :params, :current_user

  def initialize(params = {}, user = nil)
    @params = params
    @current_user = user
  end

  def results
    raise NotImplementedError, "Subclasses must implement 'results'"
  end

  def page
    (params[:page] || 1).to_i
  end

  def per_page
    limit = (params[:per_page] || 30).to_i
    [limit, 100].min
  end

  def hydrate(solr_response, model_class)
    ids = solr_response[:ids]
    records_by_id = model_class.where(id: ids).index_by(&:id)
    ordered_records = ids.map { |id| records_by_id[id.to_i] }.compact

    OpenStruct.new(
      records: ordered_records,
      total_count: solr_response[:total],
      page: page,
      per_page: per_page
    )
  end
end
