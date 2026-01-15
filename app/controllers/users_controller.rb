class UsersController < ApplicationController
  before_action :logged_in_user, only: %i[index edit update destroy]
  before_action :correct_user, only: %i[edit update]
  before_action :admin_user, only: :destroy

  def show
    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])
    redirect_to root_url and return unless @user.activated?
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
      flash[:success] = 'Profile is updated'
      redirect_to @user
    else
      render 'edit'
    end
  end

  def index
    @users = User.where(activated: true).paginate(page: params[:page])
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
    return render json: [] if query.blank?

    search = User.search do
      fulltext query do
        fields(:name, :bio)
      end
      with(:activated, true)
      paginate page: 1, per_page: 5
    end
    users = search.results.map { |u| { id: u.id, name: u.name, email: u.email } }
    render json: users
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
    render 'show_follow'
  end

  def followers
    @title = 'Followers'
    @user = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

  private

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
end
