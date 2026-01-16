class UsersController < ApplicationController
  before_action :logged_in_user, only: %i[index edit update destroy]
  before_action :correct_user, only: %i[edit update]
  before_action :admin_user, only: :destroy

  def show
    @user = User.find(params[:id])
    redirect_to root_url and return unless @user.activated?

    @microposts = @user.microposts.paginate(page: params[:page])

    respond_to do |format|
      format.html
      format.json do
        render json: {
          user: {
            id: @user.id,
            name: @user.name,
            email: @user.email,
            created_at: @user.created_at,
            microposts_count: @user.microposts.count,
            followers_count: @user.followers.count,
            following_count: @user.following.count,
            following: logged_in? ? current_user.following?(@user) : false
          },
          microposts: @microposts.map { |m|
            {
              id: m.id,
              content: m.content,
              created_at: m.created_at,
              likes_count: m.likes.count,
              comments_count: m.comments.count
            }
          },
          pagination: {
            current_page: @microposts.current_page,
            total_pages: @microposts.total_pages,
            total_count: @microposts.count
          }
        }
      end
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
      respond_to do |format|
        format.html do
          flash[:success] = 'Profile is updated'
          redirect_to @user
        end
        format.json do
          render json: {
            success: true,
            user: {
              id: @user.id,
              name: @user.name,
              email: @user.email
            }
          }
        end
      end
    else
      respond_to do |format|
        format.html { render 'edit' }
        format.json do
          render json: {
            success: false,
            errors: @user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def index
    @users = if params[:query].present?
               # Elasticsearch search with Searchkick
               User.search(
                 params[:query],
                 fields: %i[name email],
                 where: { activated: true },
                 page: params[:page],
                 per_page: 30
               )
             else
               User.where(activated: true).paginate(page: params[:page])
             end

    respond_to do |format|
      format.html
      format.json do
        total = @users.respond_to?(:total_count) ? @users.total_count : @users.count
        render json: {
          users: @users.map { |u|
            {
              id: u.id,
              name: u.name,
              email: u.email,
              followers_count: u.followers.count,
              following_count: u.following.count
            }
          },
          total: total,
          page: params[:page] || 1
        }
      end
    end
  end

  # GET /users/search
  def search
    query = params[:q] || params[:query]

    if query.blank?
      render json: { users: [], total: 0 }
      return
    end

    # Build search options
    search_options = {
      fields: %i[name email],
      where: { activated: true },
      page: params[:page] || 1,
      per_page: params[:per_page] || 20
    }

    # Add filters
    if params[:following] == 'true' && logged_in?
      following_ids = current_user.following.pluck(:id)
      search_options[:where][:id] = following_ids
    end

    if params[:followers] == 'true' && logged_in?
      follower_ids = current_user.followers.pluck(:id)
      search_options[:where][:id] = follower_ids
    end

    # Perform search
    results = User.search(query, search_options)

    respond_to do |format|
      format.json do
        render json: {
          users: results.map { |u|
            {
              id: u.id,
              name: u.name,
              email: u.email,
              followers_count: u.followers.count,
              following_count: u.following.count,
              following: logged_in? ? current_user.following?(u) : false
            }
          },
          total: results.total_count,
          page: params[:page] || 1,
          per_page: params[:per_page] || 20
        }
      end
      format.html do
        @users = results
        render :index
      end
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = 'User is deleted!'
    redirect_to users_url
  end

  def following
    @title = 'Following'
    @user = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])

    respond_to do |format|
      format.html { render 'show_follow' }
      format.json do
        render json: {
          title: @title,
          users: @users.map { |u|
            {
              id: u.id,
              name: u.name,
              email: u.email,
              followers_count: u.followers.count,
              following_count: u.following.count,
              following: logged_in? ? current_user.following?(u) : false
            }
          },
          pagination: {
            current_page: @users.current_page,
            total_pages: @users.total_pages,
            total_count: @users.count
          }
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
          title: @title,
          users: @users.map { |u|
            {
              id: u.id,
              name: u.name,
              email: u.email,
              followers_count: u.followers.count,
              following_count: u.following.count,
              following: logged_in? ? current_user.following?(u) : false
            }
          },
          pagination: {
            current_page: @users.current_page,
            total_pages: @users.total_pages,
            total_count: @users.count
          }
        }
      end
    end
  end

  # GET /users/autocomplete
  def autocomplete
    query = params[:q]

    # Search users for @ mentions
    users = if query.present?
              # Search following users first, then all activated users
              if logged_in?
                following_users = current_user.following.where('name LIKE ?', "#{query}%").limit(5)
                other_users = User.where(activated: true)
                                  .where('name LIKE ?', "#{query}%")
                                  .where.not(id: following_users.pluck(:id))
                                  .limit(5)
                (following_users + other_users).uniq.first(10)
              else
                User.where(activated: true).where('name LIKE ?', "#{query}%").limit(10)
              end
            else
              # Return following users if logged in
              logged_in? ? current_user.following.limit(10) : []
            end

    render json: {
      users: users.map { |u| { id: u.id, name: u.name, email: u.email } }
    }
  end

  private

  # Strong param
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
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
end
