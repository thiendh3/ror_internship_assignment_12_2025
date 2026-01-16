class StaticPagesController < ApplicationController
  def home
    return unless logged_in?

    setup_home_page_data

    if search_params_present?
      perform_search
    else
      load_feed
    end
  end

  def help; end

  def about; end

  def contact; end

  private

  def setup_home_page_data
    @micropost = current_user.microposts.build
    @following_users = current_user.following.order(:name)
  end

  def search_params_present?
    params[:q].present? || params[:hashtag].present? ||
      params[:user_id].present? || params[:from].present? || params[:to].present?
  end

  def perform_search
    response = MicropostSearch.search(
      query: params[:q],
      hashtag: params[:hashtag],
      user_id: params[:user_id],
      from: format_date(params[:from]),
      to: format_date(params[:to], end_of_day: true)
    )

    @highlights = response['highlighting']
    @search_results = fetch_search_results(response['response']['docs'].pluck('id'))
  end

  def format_date(date_param, end_of_day: false)
    return nil if date_param.blank?

    parsed_date = Time.zone.parse(date_param)
    parsed_date = parsed_date.end_of_day if end_of_day
    parsed_date.utc.iso8601
  end

  def fetch_search_results(micropost_ids)
    Micropost.visible_for(current_user)
             .where(id: micropost_ids)
             .includes(:user, :hashtags)
             .order(created_at: :desc)
             .paginate(page: params[:page], per_page: 10)
  end

  def load_feed
    @search_results = []
    @feed_items = current_user.feed.visible_for(current_user).paginate(page: params[:page])
  end
end
