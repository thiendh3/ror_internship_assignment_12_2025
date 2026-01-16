class UserSearch < ApplicationSearch
  def results
    raw_response = SolrService.search(
      query: build_query,
      filter_query: build_filters,
      boost_query: build_boost,
      sort: build_sort,
      page: page,
      per_page: per_page
    )
    hydrate(raw_response, User)
  end

  private

  def build_query
    query_str = RSolr.solr_escape(params[:query].to_s.strip)
    return '*:*' if query_str.blank?

    if current_user&.admin? && params[:search_field] == 'email'
      return "(email_text:#{query_str}) OR (email_ac:#{query_str}^2)"
    end

    fuzzy = query_str.length > 2 ? " OR #{query_str}~1" : ''
    "(name_text:(#{query_str}#{fuzzy})^5) OR (name_ac:#{query_str}^10)"
  end

  def build_filters
    [status_filter, scope_filter].flatten.compact
  end

  def status_filter
    return if current_user&.admin? && params[:include_deactivated] == '1'

    'active_boolean:true'
  end

  def scope_filter
    scopes = Array(params[:scope]).map(&:to_s)

    # return nil (not filter) if both filter exists
    return if scopes.include?('following') && scopes.include?('discover')

    # only following
    return following_only_filter if scopes.include?('following')

    # only discover
    return discover_only_filter if scopes.include?('discover')

    # return a filter matches nothing so that Solr returns nothing
    'id:0'
  end

  def following_only_filter
    if current_user&.following&.any?
      "id:(#{current_user.following.ids.join(' OR ')})"
    else
      'id:0'
    end
  end

  def discover_only_filter
    filters = []
    filters << "-id:(#{current_user.following.ids.join(' OR ')})" if current_user&.following&.any?
    filters << "-id:#{current_user.id}" if current_user
    filters
  end

  def build_sort
    case params[:sort]
    when 'newest'  then 'created_at_dt desc'
    when 'popular' then 'followers_count_i desc'
    when 'oldest'  then 'created_at_dt asc'
    else 'score desc'
    end
  end

  def build_boost
    return nil unless current_user&.following&.any?

    scopes = Array(params[:scope]).map(&:to_s)
    return nil if scopes.include?('discover') && !scopes.include?('following')

    "id:(#{current_user.following.ids.join(' ')})^5"
  end
end
