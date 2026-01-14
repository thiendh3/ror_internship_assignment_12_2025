class StaticPagesController < ApplicationController
  def home
    if logged_in?
      @micropost = current_user.microposts.build
      @following_users = current_user.following.order(:name)
      
      # Handle search if any filter is present
      if params[:q].present? || params[:hashtag].present? || params[:user_id].present? || params[:from].present? || params[:to].present?
        # Format dates for Solr if present
        from_date = params[:from].present? ? Time.zone.parse(params[:from]).utc.iso8601 : nil
        to_date = params[:to].present? ? Time.zone.parse(params[:to]).end_of_day.utc.iso8601 : nil
        
        response = MicropostSearch.search(
          q: params[:q],
          hashtag: params[:hashtag],
          user_id: params[:user_id],
          from: from_date,
          to: to_date
        )
        # Get micropost IDs from Solr results
        micropost_ids = response['response']['docs'].map { |doc| doc['id'] }
        # Store highlighting data
        @highlights = response['highlighting']
        # Fetch actual Micropost objects from database with pagination
        @search_results = Micropost.where(id: micropost_ids)
                                   .includes(:user, :hashtags)
                                   .order(created_at: :desc)
                                   .paginate(page: params[:page], per_page: 10)
      else
        @search_results = []
        @feed_items = current_user.feed.paginate(page: params[:page])
      end
    end
  end

  def help
  end

  def about
  end

  def contact
  end
end
