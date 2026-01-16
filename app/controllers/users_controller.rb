require 'digest'

class UsersController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_action :logged_in_user, only: %i[index edit update destroy autocomplete]
  before_action :correct_user, only: %i[edit update]
  before_action :admin_user, only: :destroy

  def show
    @user = User.find(params[:id])
    redirect_to root_url and return unless @user.activated?

    # All microposts including shared ones, filtered by visibility
    @microposts = @user.microposts.includes(:user, :original_post)
                       .visible_to(current_user).to_a

    # Get all photos from user's posts (for Photos tab)
    @user_photos = @user.microposts.select { |post| post.image.attached? }.map(&:display_image).compact

    # Get mutual friends (users who follow each other)
    follower_ids = @user.followers.pluck(:id)
    following_ids = @user.following.pluck(:id)
    mutual_ids = follower_ids & following_ids
    @mutual_friends = User.where(id: mutual_ids)

    # Get all followers and following for Friends tab
    @all_followers = @user.followers
    @all_following = @user.following

    respond_to do |format|
      format.html
      format.json { render json: user_json(@user) }
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      flash[:info] = 'Please check your email to activate your account.'
      redirect_to root_url
      # log_in @user
      # flash[:success] = "Welcome to the Sample App!"
      # redirect_to @user
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      handle_user_update_success
    else
      handle_user_update_failure
    end
  end

  def index
    @users = User.where(activated: true).paginate(page: params[:page])

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: render_to_string(partial: 'users/user_list', locals: { users: @users }, formats: [:html]),
          pagination: render_to_string(partial: 'shared/pagination', locals: { collection: @users }, formats: [:html])
        }
      end
    end
  end

  def microposts
    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page], per_page: 10)

    respond_to do |format|
      format.html { redirect_to @user }
      format.json do
        render json: {
          html: render_to_string(partial: 'microposts/micropost', collection: @microposts, formats: [:html]),
          pagination: render_to_string(partial: 'shared/ajax_pagination',
                                       locals: { collection: @microposts, user: @user }, formats: [:html]),
          total: @user.microposts.count,
          page: params[:page] || 1
        }
      end
    end
  end

  def search
    @search_service = UserSearchService.new(params, current_user)
    @query = @search_service.query
    @filter = @search_service.filter
    @min_followers = @search_service.min_followers
    @min_following = @search_service.min_following

    @search = @search_service.search
    @users = @search.results
    @highlights = build_highlights(@search)

    respond_to do |format|
      format.html
      format.js
      format.json { render json: search_json_response }
    end
  end

  def autocomplete
    query = params[:q].to_s.strip
    return render json: { users: [] } if query.blank?

    # Use UserSearchService for consistent search logic
    @search_service = UserSearchService.new(params, current_user)
    @search = @search_service.search
    @users = @search.results
    @highlights = build_highlights(@search)

    render json: { users: map_autocomplete_users }
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = 'User is deleted!'
    redirect_to users_url
  end

  private

  def relationship_status(user)
    return nil unless logged_in?
    return 'Friend' if current_user.following?(user) && user.following?(current_user)
    return 'Following' if current_user.following?(user)
    return 'Follower' if user.following?(current_user)

    nil
  end

  def new_posts_count(_user)
    0 unless logged_in?
  end

  def gravatar_url_for(user, size: 80)
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=identicon"
  end

  def following
    @title = 'Following'
    @user = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])

    respond_to do |format|
      format.html { render 'show_follow' }
      format.json do
        render json: {
          html: render_to_string(partial: 'users/user_list', locals: { users: @users }, formats: [:html]),
          pagination: render_to_string(partial: 'shared/pagination', locals: { collection: @users }, formats: [:html]),
          count: @user.following.count
        }
      end
    end
  end

  def followers
    @title = 'Followers'
    @user = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])

    respond_to do |format|
      format.html { render 'show_follow' }
      format.json do
        render json: {
          html: render_to_string(partial: 'users/user_list', locals: { users: @users }, formats: [:html]),
          pagination: render_to_string(partial: 'shared/pagination', locals: { collection: @users }, formats: [:html]),
          count: @user.followers.count
        }
      end
    end
  end

  def map_autocomplete_users
    @users.map do |user|
      highlights = @highlights[user.id] || {}
      {
        id: user.id,
        name: user.name,
        avatar_url: gravatar_url_for(user, size: 40),
        relationship: relationship_status(user),
        new_posts_count: new_posts_count(user),
        highlights: {
          name: highlights[:name]&.format { |word| "<mark>#{word}</mark>" },
          bio: highlights[:bio]&.format { |word| "<mark>#{word}</mark>" }
        }
      }
    end
  end

  def build_highlights(search)
    search.hits.each_with_object({}) do |hit, hash|
      field_highlights = {}
      hit.highlights.each do |hl|
        field_highlights[hl.field_name] = hl
      end
      hash[hit.primary_key.to_i] = field_highlights
    end
  end

  def search_json_response
    @users.map do |user|
      highlights = @highlights[user.id] || {}
      {
        id: user.id,
        name: user.name,
        email: user.email,
        bio: user.bio,
        highlights: {
          name: highlights[:name]&.format { |word| "<mark>#{word}</mark>" },
          email: highlights[:email]&.format { |word| "<mark>#{word}</mark>" },
          bio: highlights[:bio]&.format { |word| "<mark>#{word}</mark>" }
        }
      }
    end
  end

  def handle_user_update_success
    respond_to do |format|
      format.html do
        flash[:success] = 'Profile is updated'
        redirect_to @user
      end
      format.json do
        render json: {
          name: @user.name,
          email: @user.email,
          bio: @user.bio
        }, status: :ok
      end
    end
  end

  def handle_user_update_failure
    respond_to do |format|
      format.html { render 'edit' }
      format.json do
        render json: {
          errors: @user.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  end

  # Strong param
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :bio)
  end

  # Before filter

  # Confirm the correct user
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end

  # Confirm admin user
  def admin_user
    redirect_to(root_url) unless current_user.admin?
  end

  def user_json(user)
    result = {
      id: user.id,
      name: user.name,
      email: user.email,
      bio: user.bio,
      gravatar_url: gravatar_url(user, size: 80),
      microposts_count: user.microposts.count,
      following_count: user.following.count,
      followers_count: user.followers.count
    }

    if logged_in? && current_user != user
      relationship = current_user.active_relationships.find_by(followed_id: user.id)
      result[:is_following] = relationship.present?
      result[:relationship_id] = relationship&.id
      result[:follow_button_html] = render_follow_button(user, relationship)
    end

    result
  end

  def gravatar_url(user, size: 80)
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
  end

  def render_follow_button(user, relationship)
    button_style = 'padding: 8px 24px; color: white; border: none; border-radius: 4px; cursor: pointer;'
    if relationship
      background = 'background: #6c757d;'
      "<button class='follow-btn' data-user-id='#{user.id}' data-following='true' " \
        "data-relationship-id='#{relationship.id}' style='#{button_style} #{background}'>Unfollow</button>"
    else
      background = 'background: #0d6efd;'
      "<button class='follow-btn' data-user-id='#{user.id}' data-following='false' " \
        "style='#{button_style} #{background}'>Follow</button>"
    end
  end
end
