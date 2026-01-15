class CommentsController < ApplicationController
  before_action :logged_in_user
  before_action :set_micropost

  # GET /microposts/:micropost_id/comments
  def index
    @comments = @micropost.comments.includes(:user).order(created_at: :desc)

    respond_to do |format|
      format.json { 
        render json: @comments.map { |comment| 
          { 
            id: comment.id,
            content: comment.content,
            user: {
              id: comment.user.id,
              name: comment.user.name
            },
            created_at: comment.created_at,
            can_delete: current_user == comment.user || current_user == @micropost.user
          }
        }
      }
      format.html
    end
  end

  # POST /microposts/:micropost_id/comments
  def create
    @comment = @micropost.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.json { 
          render json: { 
            success: true,
            comment: {
              id: @comment.id,
              content: @comment.content,
              user: {
                id: @comment.user.id,
                name: @comment.user.name
              },
              created_at: @comment.created_at,
              can_delete: true
            },
            comments_count: @micropost.comments_count,
            message: 'Comment created successfully'
          }, status: :created 
        }
        format.html { redirect_to request.referrer || root_url }
      else
        format.json { 
          render json: { 
            success: false, 
            errors: @comment.errors.full_messages 
          }, status: :unprocessable_entity 
        }
        format.html { redirect_to request.referrer || root_url, alert: 'Unable to comment' }
      end
    end
  end

  # DELETE /microposts/:micropost_id/comments/:id
  def destroy
    @comment = @micropost.comments.find(params[:id])
    
    # Only comment owner or micropost owner can delete
    unless current_user == @comment.user || current_user == @micropost.user
      respond_to do |format|
        format.json { render json: { success: false, message: 'Unauthorized' }, status: :forbidden }
        format.html { redirect_to request.referrer || root_url, alert: 'Unauthorized' }
      end
      return
    end

    respond_to do |format|
      if @comment.destroy
        format.json { 
          render json: { 
            success: true,
            comments_count: @micropost.reload.comments_count,
            message: 'Comment deleted successfully'
          }, status: :ok 
        }
        format.html { redirect_to request.referrer || root_url }
      else
        format.json { 
          render json: { 
            success: false, 
            message: 'Unable to delete comment' 
          }, status: :unprocessable_entity 
        }
        format.html { redirect_to request.referrer || root_url, alert: 'Unable to delete comment' }
      end
    end
  end

  private

  def set_micropost
    @micropost = Micropost.find(params[:micropost_id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
