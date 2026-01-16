class UserSearch < ApplicationSearch
  def results
    raw_response = SolrService.search(
      q: build_query,
      fq: build_filters,
      bq: build_boost,
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
    fqs = []

    fqs << 'active_boolean:true' unless current_user&.admin? && params[:include_deactivated] == '1'

    current_scopes = Array(params[:scope]).map(&:to_s)
    has_following = current_scopes.include?('following')
    has_discover  = current_scopes.include?('discover')

    if has_following && has_discover
      # No filter
    elsif has_following
      fqs << if current_user&.following&.any?
               "id:(#{current_user.following.ids.join(' OR ')})"
             else
               'id:0'
             end
    elsif has_discover
      fqs << "-id:(#{current_user.following.ids.join(' OR ')})" if current_user&.following&.any?
      fqs << "-id:#{current_user.id}" if current_user
    else
      fqs << 'id:0'
    end

    fqs
  end

  def build_sort
    case params[:sort]
    when 'newest'
      'created_at_dt desc'
    when 'popular'
      'followers_count_i desc'
    when 'oldest'
      'created_at_dt asc'
    else
      'score desc'
    end
  end

  def build_boost
    return nil unless current_user&.following&.any?

    scopes = Array(params[:scope]).map(&:to_s)
    return nil if scopes.include?('discover') && !scopes.include?('following')

    "id:(#{current_user.following.ids.join(' ')})^5"
  end
end
