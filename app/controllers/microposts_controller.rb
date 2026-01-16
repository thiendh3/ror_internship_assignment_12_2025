class MicropostsController < ApplicationController
  before_action :logged_in_user, only: %i[create destroy update show]
  before_action :correct_user, only: %i[destroy update]
  before_action :set_micropost, only: %i[show update]

  # GET /microposts/:id
  def show
    return handle_unauthorized_show unless MicropostPolicy.new(current_user, @micropost).show?

    respond_to do |format|
      handle_show_response(format)
    end
  end

  # POST /microposts
  def create
    @micropost = current_user.microposts.build(micropost_params)
    @micropost.image.attach(params[:micropost][:image]) if params[:micropost][:image].present?

    respond_to do |format|
      if @micropost.save
        handle_create_success(format)
      else
        handle_create_failure(format)
      end
    end
  end

  # PATCH/PUT /microposts/:id
  def update
    respond_to do |format|
      if @micropost.update(micropost_params)
        handle_update_success(format)
      else
        handle_update_failure(format)
      end
    end
  end

  # DELETE /microposts/:id
  def destroy
    respond_to do |format|
      if @micropost.destroy
        handle_destroy_success(format)
      else
        handle_destroy_failure(format)
      end
    end
  end

  # GET /microposts/search
  def search
    query = params[:q]
    page, per_page = search_pagination_params
    search_options = build_search_options(page, per_page)
    results = perform_micropost_search(query, search_options)
    filtered_results = filter_search_results(results)

    @query = query

    respond_to do |format|
      handle_search_response(format, filtered_results, results, page, per_page)
    end
  end

  # GET /microposts/autocomplete
  def autocomplete
    query = params[:q]

    # Autocomplete for hashtags
    suggestions = if query.present?
                    Hashtag.where('name LIKE ?', "#{query}%").limit(10).pluck(:name)
                  else
                    Hashtag.order(created_at: :desc).limit(10).pluck(:name)
                  end

    render json: { suggestions: suggestions }
  end

  private

  def handle_unauthorized_show
    respond_to do |format|
      format.json { render json: { success: false, message: 'Unauthorized' }, status: :forbidden }
      format.html { redirect_to root_url, alert: 'You cannot view this micropost' }
    end
  end

  def handle_show_response(format)
    format.json do
      render json: micropost_json(@micropost).merge(
        liked_by_current_user: @micropost.liked_by?(current_user)
      )
    end
    format.html
  end

  def handle_create_success(format)
    format.json do
      render json: {
        success: true,
        micropost: micropost_json(@micropost),
        message: 'Micropost created!'
      }, status: :created
    end
    format.html do
      flash[:success] = 'Micropost created!'
      redirect_to root_url
    end
  end

  def handle_create_failure(format)
    format.json do
      render json: {
        success: false,
        errors: @micropost.errors.full_messages
      }, status: :unprocessable_entity
    end
    format.html do
      @feed_items = current_user.feed.paginate(page: params[:page])
      render 'static_pages/home', status: :unprocessable_entity
    end
  end

  def handle_update_success(format)
    format.json do
      render json: {
        success: true,
        micropost: micropost_json(@micropost).merge(updated_at: @micropost.updated_at),
        message: 'Micropost updated successfully'
      }, status: :ok
    end
    format.html do
      flash[:success] = 'Micropost updated!'
      redirect_to request.referrer || root_url
    end
  end

  def handle_update_failure(format)
    format.json do
      render json: {
        success: false,
        errors: @micropost.errors.full_messages
      }, status: :unprocessable_entity
    end
    format.html do
      redirect_to request.referrer || root_url, alert: 'Unable to update micropost'
    end
  end

  def handle_destroy_success(format)
    format.json do
      render json: {
        success: true,
        message: 'Micropost deleted successfully'
      }, status: :ok
    end
    format.html do
      flash[:success] = 'Micropost is deleted'
      redirect_to request.referrer || root_url
    end
  end

  def handle_destroy_failure(format)
    format.json do
      render json: {
        success: false,
        message: 'Unable to delete micropost'
      }, status: :unprocessable_entity
    end
    format.html do
      redirect_to request.referrer || root_url, alert: 'Unable to delete micropost'
    end
  end

  def micropost_json(micropost)
    {
      id: micropost.id,
      content: micropost.content,
      privacy: micropost.privacy,
      likes_count: micropost.likes_count,
      comments_count: micropost.comments_count,
      created_at: micropost.created_at,
      user: {
        id: micropost.user.id,
        name: micropost.user.name
      },
      hashtags: micropost.hashtags.pluck(:name)
    }
  end

  def search_pagination_params
    [params[:page] || 1, params[:per_page] || 20]
  end

  def build_search_options(page, per_page)
    options = {
      page: page,
      per_page: per_page,
      highlight: { fields: { content: {} } }
    }

    where_clause = build_search_where_clause
    options[:where] = where_clause if where_clause.any?
    options
  end

  def build_search_where_clause
    where_clause = {}
    where_clause[:user_id] = params[:user_id] if params[:user_id].present?
    where_clause[:hashtags] = params[:hashtag] if params[:hashtag].present?
    where_clause[:privacy] = params[:privacy] if params[:privacy].present?

    if params[:start_date].present? && params[:end_date].present?
      where_clause[:created_at] = {
        gte: params[:start_date],
        lte: params[:end_date]
      }
    end

    where_clause
  end

  def perform_micropost_search(query, search_options)
    search_term = query.presence || '*'
    Micropost.search(search_term, **search_options)
  end

  def filter_search_results(results)
    results.select do |micropost|
      MicropostPolicy.new(current_user, micropost).show?
    end
  end

  def handle_search_response(format, filtered_results, results, page, per_page)
    format.json do
      render json: {
        microposts: filtered_results.map { |micropost| micropost_json_with_highlight(micropost, results) },
        total: filtered_results.count,
        page: page.to_i,
        per_page: per_page.to_i
      }
    end
    format.html do
      @microposts = filtered_results
    end
  end

  def micropost_json_with_highlight(micropost, results)
    micropost_json(micropost).merge(
      highlight: results.try(:highlights) ? results.highlights[micropost]&.dig(:content)&.first : nil
    )
  end

  def micropost_params
    params.require(:micropost).permit(:content, :image, :privacy)
  end

  def correct_user
    @micropost = current_user.microposts.find_by(id: params[:id])
    redirect_to root_url if @micropost.nil?
  end

  def set_micropost
    @micropost = Micropost.find(params[:id])
  end
end
