# frozen_string_literal: true

class UserSearchService
  attr_reader :query, :filter, :min_followers, :min_following, :current_user, :page

  def initialize(params, current_user)
    @query = params[:q].to_s.strip
    @filter = params[:filter]
    @min_followers = params[:min_followers].to_i if params[:min_followers].present?
    @min_following = params[:min_following].to_i if params[:min_following].present?
    @current_user = current_user
    @page = params[:page] || 1
  end

  def search
    search_params = build_search_params
    User.search(&search_params)
  end

  private

  def build_search_params
    q = prepare_query(query)
    f = filter
    min_fol = min_followers
    min_fow = min_following
    curr = current_user
    is_admin = curr&.admin?
    pg = page
    filter_ids = following_filter_ids

    proc do
      fulltext_search(q, is_admin) if q.present?
      with(:activated, true)
      apply_following_filter(f, filter_ids)
      apply_count_filters(min_fol, min_fow)
      paginate page: pg, per_page: 10
    end
  end

  def prepare_query(q)
    return nil if q.blank?
    # Add wildcard for partial matching
    q.split.map { |term| "#{term}*" }.join(' ')
  end

  def following_filter_ids
    return nil unless current_user && %w[following followers].include?(filter)

    filter == 'following' ? current_user.following.pluck(:id) : current_user.followers.pluck(:id)
  end
end

# Extend Sunspot DSL for cleaner code
module Sunspot
  module DSL
    class Search
      def fulltext_search(query, is_admin)
        fulltext query do
          fields(:name, :bio)
          fields(:email) if is_admin
          highlight :name, :email, :bio
        end
      end

      def apply_following_filter(_filter, filter_ids)
        return unless filter_ids

        with(:id, filter_ids)
      end

      def apply_count_filters(min_followers, min_following)
        with(:followers_count).greater_than_or_equal_to(min_followers) if min_followers&.positive?
        with(:following_count).greater_than_or_equal_to(min_following) if min_following&.positive?
      end
    end
  end
end
