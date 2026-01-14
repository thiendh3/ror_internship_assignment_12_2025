class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy, :show, :update]
  before_action :correct_user, only: [:destroy, :update]
  before_action :set_micropost, only: [:show]

  def create
    @micropost = current_user.microposts.build(micropost_params)
    @micropost.image.attach(params[:micropost][:image]) if params[:micropost][:image].present?
    
    respond_to do |format|
      if @micropost.save
        format.html {
          flash[:success] = "Micropost created!"
          redirect_to root_url
        }
        format.json { render json: { success: true, micropost: render_to_string(partial: 'microposts/micropost', locals: { micropost: @micropost }, formats: [:html]) } }
      else
        format.html {
          @feed_items = current_user.feed.paginate(page: params[:page])
          render 'static_pages/home'
        }
        format.json { render json: { success: false, errors: @micropost.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { render json: { micropost: @micropost.as_json(include: { user: { only: [:id, :name] }, hashtags: { only: [:name] } }, methods: [:display_image_url]) } }
    end
  end

  def update
    respond_to do |format|
      if @micropost.update(micropost_params)
        format.html {
          flash[:success] = "Micropost updated!"
          redirect_to root_url
        }
        format.json { render json: { success: true, micropost: render_to_string(partial: 'microposts/micropost', locals: { micropost: @micropost }, formats: [:html]) } }
      else
        format.json { render json: { success: false, errors: @micropost.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @micropost.destroy
    respond_to do |format|
      format.html {
        flash[:success] = "Micropost is deleted"
        redirect_to request.referrer || root_url
      }
      format.json { render json: { success: true, message: "Micropost deleted" } }
    end
  end

  private
    def micropost_params
      params.require(:micropost).permit(:content, :image)
    end

    def correct_user
      @micropost = current_user.microposts.find_by(id: params[:id])
      if @micropost.nil?
        respond_to do |format|
          format.html { redirect_to root_url }
          format.json { render json: { success: false, error: "Not authorized" }, status: :forbidden }
        end
      end
    end

    def set_micropost
      @micropost = Micropost.find(params[:id])
    end
end
