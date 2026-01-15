class LikesController < ApplicationController
  before_action :logged_in_user

  # POST /microposts/:micropost_id/likes
  def create
    @micropost = Micropost.find(params[:micropost_id])
    @like = @micropost.likes.build(user: current_user)

    respond_to do |format|
      if @like.save
        format.json { 
          render json: { 
            success: true, 
            like_id: @like.id,
            likes_count: @micropost.likes_count,
            message: 'Liked successfully'
          }, status: :created 
        }
        format.html { redirect_to request.referrer || root_url }
      else
        format.json { 
          render json: { 
            success: false, 
            errors: @like.errors.full_messages 
          }, status: :unprocessable_entity 
        }
        format.html { redirect_to request.referrer || root_url, alert: 'Unable to like' }
      end
    end
  end

  # DELETE /microposts/:micropost_id/likes/:id
  def destroy
    @micropost = Micropost.find(params[:micropost_id])
    @like = @micropost.likes.find_by(user: current_user)

    respond_to do |format|
      if @like&.destroy
        format.json { 
          render json: { 
            success: true, 
            likes_count: @micropost.reload.likes_count,
            message: 'Unliked successfully'
          }, status: :ok 
        }
        format.html { redirect_to request.referrer || root_url }
      else
        format.json { 
          render json: { 
            success: false, 
            message: 'Unable to unlike' 
          }, status: :unprocessable_entity 
        }
        format.html { redirect_to request.referrer || root_url, alert: 'Unable to unlike' }
      end
    end
  end

  # GET /microposts/:micropost_id/likes
  def index
    @micropost = Micropost.find(params[:micropost_id])
    @likes = @micropost.likes.includes(:user)

    respond_to do |format|
      format.json { 
        render json: @likes.map { |like| 
          { 
            id: like.id,
            user: {
              id: like.user.id,
              name: like.user.name,
              email: like.user.email
            },
            created_at: like.created_at
          }
        }
      }
      format.html
    end
  end
end
