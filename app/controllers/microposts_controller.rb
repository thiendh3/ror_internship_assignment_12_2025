class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy, :update, :show]
  before_action :correct_user, only: [:destroy, :update]
  before_action :set_micropost, only: [:show, :update]

  # GET /microposts/:id
  def show
    # Check if user can view this micropost
    policy = MicropostPolicy.new(current_user, @micropost)
    unless policy.show?
      respond_to do |format|
        format.json { render json: { success: false, message: 'Unauthorized' }, status: :forbidden }
        format.html { redirect_to root_url, alert: 'You cannot view this micropost' }
      end
      return
    end

    respond_to do |format|
      format.json {
        render json: {
          id: @micropost.id,
          content: @micropost.content,
          privacy: @micropost.privacy,
          likes_count: @micropost.likes_count,
          comments_count: @micropost.comments_count,
          created_at: @micropost.created_at,
          user: {
            id: @micropost.user.id,
            name: @micropost.user.name
          },
          liked_by_current_user: @micropost.liked_by?(current_user),
          hashtags: @micropost.hashtags.pluck(:name)
        }
      }
      format.html
    end
  end

  # POST /microposts
  def create
    @micropost = current_user.microposts.build(micropost_params)
    @micropost.image.attach(params[:micropost][:image]) if params[:micropost][:image].present?
    
    respond_to do |format|
      if @micropost.save
        format.json {
          render json: {
            success: true,
            micropost: {
              id: @micropost.id,
              content: @micropost.content,
              privacy: @micropost.privacy,
              likes_count: @micropost.likes_count,
              comments_count: @micropost.comments_count,
              created_at: @micropost.created_at,
              user: {
                id: @micropost.user.id,
                name: @micropost.user.name
              },
              hashtags: @micropost.hashtags.pluck(:name)
            },
            message: 'Micropost created!'
          }, status: :created
        }
        format.html {
          flash[:success] = "Micropost created!"
          redirect_to root_url
        }
      else
        format.json {
          render json: {
            success: false,
            errors: @micropost.errors.full_messages
          }, status: :unprocessable_entity
        }
        format.html {
          @feed_items = current_user.feed.paginate(page: params[:page])
          render 'static_pages/home', status: :unprocessable_entity
        }
      end
    end
  end

  # PATCH/PUT /microposts/:id
  def update
    respond_to do |format|
      if @micropost.update(micropost_params)
        format.json {
          render json: {
            success: true,
            micropost: {
              id: @micropost.id,
              content: @micropost.content,
              privacy: @micropost.privacy,
              likes_count: @micropost.likes_count,
              comments_count: @micropost.comments_count,
              updated_at: @micropost.updated_at,
              hashtags: @micropost.hashtags.pluck(:name)
            },
            message: 'Micropost updated successfully'
          }, status: :ok
        }
        format.html {
          flash[:success] = "Micropost updated!"
          redirect_to request.referrer || root_url
        }
      else
        format.json {
          render json: {
            success: false,
            errors: @micropost.errors.full_messages
          }, status: :unprocessable_entity
        }
        format.html {
          redirect_to request.referrer || root_url, alert: 'Unable to update micropost'
        }
      end
    end
  end

  # DELETE /microposts/:id
  def destroy
    respond_to do |format|
      if @micropost.destroy
        format.json {
          render json: {
            success: true,
            message: 'Micropost deleted successfully'
          }, status: :ok
        }
        format.html {
          flash[:success] = "Micropost is deleted"
          redirect_to request.referrer || root_url
        }
      else
        format.json {
          render json: {
            success: false,
            message: 'Unable to delete micropost'
          }, status: :unprocessable_entity
        }
        format.html {
          redirect_to request.referrer || root_url, alert: 'Unable to delete micropost'
        }
      end
    end
  end

  # GET /microposts/search
  def search
    query = params[:q]
    page = params[:page] || 1
    per_page = params[:per_page] || 20

    # Build search options
    search_options = {
      page: page,
      per_page: per_page,
      highlight: { fields: { content: {} } }
    }

    # Add filters
    where_clause = {}
    
    # Filter by user if provided
    where_clause[:user_id] = params[:user_id] if params[:user_id].present?
    
    # Filter by hashtag if provided
    where_clause[:hashtags] = params[:hashtag] if params[:hashtag].present?
    
    # Filter by privacy if provided
    where_clause[:privacy] = params[:privacy] if params[:privacy].present?
    
    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      where_clause[:created_at] = {
        gte: params[:start_date],
        lte: params[:end_date]
      }
    end

    search_options[:where] = where_clause if where_clause.any?

    # Perform search
    results = if query.present?
      Micropost.search(query, **search_options)
    else
      Micropost.search('*', **search_options)
    end

    # Filter results by privacy policy
    filtered_results = results.select do |micropost|
      policy = MicropostPolicy.new(current_user, micropost)
      policy.show?
    end

    respond_to do |format|
      format.json {
        render json: {
          microposts: filtered_results.map { |micropost|
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
              hashtags: micropost.hashtags.pluck(:name),
              highlight: results.try(:highlights) ? results.highlights[micropost]&.dig(:content)&.first : nil
            }
          },
          total: filtered_results.count,
          page: page.to_i,
          per_page: per_page.to_i
        }
      }
      format.html {
        @microposts = filtered_results
        @query = query
      }
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
