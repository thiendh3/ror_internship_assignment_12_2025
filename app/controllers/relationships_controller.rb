class RelationshipsController < ApplicationController
  before_action :logged_in_user

  def create
    @user = User.find(params[:followed_id])
    current_user.follow(@user)
    @relationship = current_user.active_relationships.find_by(followed_id: @user.id)

    respond_to do |format|
      format.html { redirect_to @user }
      format.js
      format.json do
        render json: {
          success: true,
          relationship_id: @relationship&.id,
          followers_count: @user.followers.count
        }
      end
    end
  end

  def destroy
    @user = Relationship.find(params[:id]).followed
    current_user.unfollow(@user)

    respond_to do |format|
      format.html { redirect_to @user }
      format.js
      format.json do
        render json: {
          success: true,
          followers_count: @user.followers.count
        }
      end
    end
  end
end
