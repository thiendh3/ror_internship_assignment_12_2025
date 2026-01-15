class RelationshipsController < ApplicationController
  before_action :logged_in_user

  def create
    @user = User.find(params[:followed_id])

    # Use find_or_create_by to avoid duplicate relationships when button is clicked multiple times
    relationship = current_user.active_relationships.find_or_create_by!(followed_id: @user.id)

    respond_to do |format|
      format.html { redirect_to @user }
      format.js
      format.json do
        render json: {
          success: true,
          relationship_id: relationship.id,
          following: true
        }
      end
    end
  end

  def destroy
    @relationship = Relationship.find(params[:id])
    @user = @relationship.followed
    current_user.unfollow(@user)
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
      format.json do
        render json: {
          success: true,
          following: false
        }
      end
    end
  end
end
