class MicropostsController < ApplicationController
  before_action :logged_in_user, only: %i[create destroy show update]
  before_action :correct_user, only: %i[destroy update]
  before_action :set_micropost, only: [:show]

  def show
    @comments = @micropost.comments.includes(:user).order(created_at: :asc)

    respond_to do |format|
      format.html # Will render show.html.slim
      format.json do
        render json: {
          micropost: @micropost.as_json(
            include: {
              user: { only: %i[id name], methods: [:gravatar_url] },
              hashtags: { only: [:name] },
              comments: {
                include: {
                  user: { only: %i[id name], methods: [:gravatar_url] }
                }
              }
            },
            methods: %i[display_image_url likes_count]
          )
        }
      end
    end
  end

  def create
    @micropost = current_user.microposts.build(micropost_params)
    @micropost.image.attach(params[:micropost][:image]) if params[:micropost][:image].present?

    respond_to do |format|
      if @micropost.save
        broadcast_new_micropost
        handle_create_success(format)
      else
        handle_create_failure(format)
      end
    end
  end

  def update
    # Handle image attachment
    @micropost.image.attach(params[:micropost][:image]) if params[:micropost][:image].present?

    # Handle image removal
    @micropost.image.purge if params[:micropost][:remove_image] == '1'

    respond_to do |format|
      if @micropost.update(micropost_params)
        format.html do
          flash[:success] = 'Micropost updated!'
          redirect_to root_url
        end
        format.json do
          render json: { success: true,
                         micropost: render_to_string(partial: 'microposts/micropost', locals: { micropost: @micropost },
                                                     formats: [:html]) }
        end
      else
        format.json do
          render json: { success: false, errors: @micropost.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @micropost.destroy
    respond_to do |format|
      format.html do
        flash[:success] = 'Micropost is deleted'
        redirect_to request.referer || root_url
      end
      format.json { render json: { success: true, message: 'Micropost deleted' } }
    end
  end

  private

  def micropost_params
    params.require(:micropost).permit(:content, :image, :privacy)
  end

  def broadcast_new_micropost
    ActionCable.server.broadcast(
      'microposts',
      {
        id: @micropost.id,
        user: build_user_data(@micropost.user),
        content: @micropost.content,
        created_at: @micropost.created_at,
        html: render_micropost_partial
      }
    )
  end

  def build_user_data(user)
    {
      id: user.id,
      name: user.name,
      gravatar_url: user.gravatar_url
    }
  end

  def render_micropost_partial
    render_to_string(partial: 'microposts/micropost', locals: { micropost: @micropost }, formats: [:html])
  end

  def handle_create_success(format)
    format.html do
      flash[:success] = 'Micropost created!'
      redirect_to root_url
    end
    format.json { render json: { success: true, micropost: render_micropost_partial } }
  end

  def handle_create_failure(format)
    format.html do
      @feed_items = current_user.feed.paginate(page: params[:page])
      render 'static_pages/home'
    end
    format.json do
      render json: { success: false, errors: @micropost.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  def correct_user
    @micropost = current_user.microposts.find_by(id: params[:id])
    return unless @micropost.nil?

    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { render json: { success: false, error: 'Not authorized' }, status: :forbidden }
    end
  end

  def set_micropost
    @micropost = Micropost.visible_for(current_user).find_by(id: params[:id])
    return if @micropost

    respond_to do |format|
      format.html do
        flash[:danger] = "Post not found or you don't have permission to view it"
        redirect_to root_url
      end
      format.json { render json: { error: 'Not found or unauthorized' }, status: :not_found }
    end
  end
end
