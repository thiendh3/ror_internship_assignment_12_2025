class CommentsController < ApplicationController
  before_action :logged_in_user
  
  def create
    @micropost = Micropost.find(params[:micropost_id])
    @comment = @micropost.comments.build(comment_params)
    @comment.user = current_user
    
    if @comment.save
      # Create notification for micropost owner
      NotificationService.create_comment_notification(current_user, @micropost, @comment)
      
      respond_to do |format|
        format.html { redirect_to @micropost }
        format.json { 
          render json: { 
            comment: @comment.as_json(
              include: {
                user: { only: [:id, :name], methods: [:gravatar_url] }
              }
            )
          }, status: :created 
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to @micropost, alert: "Comment can't be blank" }
        format.json { render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @comment = current_user.comments.find_by(id: params[:id])
    if @comment
      @comment.destroy
      respond_to do |format|
        format.html { redirect_to micropost_path(@comment.micropost) }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Comment not found" }
        format.json { render json: { error: "Not authorized" }, status: :forbidden }
      end
    end
  end
  
  private
  
  def comment_params
    params.require(:comment).permit(:content)
  end
end
