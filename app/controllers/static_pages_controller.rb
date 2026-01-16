class StaticPagesController < ApplicationController
  def home
    return unless logged_in?

    @micropost = current_user.microposts.build
    @feed_items = current_user.feed.paginate(page: params[:page])
    # For right sidebar - contacts (following users)
    @following_users = current_user.following.limit(10)
    # For right sidebar - suggested users (users not following yet)
    following_ids = current_user.following.pluck(:id) + [current_user.id]
    @suggested_users = User.where(activated: true).where.not(id: following_ids).limit(5)
  end

  def help; end

  def about; end

  def contact; end
end
