class UsersController < ApplicationController
  require 'will_paginate/array'

  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: :destroy

  def show
    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])
    redirect_to root_url and return unless @user.activated?
    
    render layout: false if turbo_frame_request?
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def edit_modal
    @user = User.find(params[:id])
    render layout: false
  end

  # NEED UPDATE
  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash[:success] = "Profile is updated"
      
      respond_to do |format|
        format.html { redirect_to @user }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "edit_user_form", 
            "<script>window.location.href = '#{user_path(@user)}'</script>".html_safe
          )
        end
      end
    else
      respond_to do |format|
        format.html { render 'edit', status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("edit_user_form", partial: "users/form_modal")
        end
      end
    end
  end

  def index
    @search = UserSearch.new(params, current_user)
    result = @search.results

    @users = WillPaginate::Collection.create(result.page, result.per_page, result.total_count) do |pager|
      pager.replace(result.records)
    end
    
    @total_found = result.total_count
    @filter_type = params[:filter]
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User is deleted!"
    redirect_to users_url
  end

  def following
    @title = "Following"
    @user = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "Followers"
    @user = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'
  end

  def autocomplete
    query = params[:query].to_s.strip
    return render json: { queries: [] } if query.blank?

    search = UserSearch.new(
      query: query, 
      search_field: params[:search_field], 
      page: 1, 
      per_page: 30, 
      user: current_user
    )
    result = search.results
    result = search.results
    
    suggestions = result.records.flat_map do |user|
      # if searching email, suggest email parts
      if current_user&.admin? && params[:search_field] == 'email'
        [user.email]
      else
        # otherwise suggest name parts
        user.name.split(/\s+/)
      end
    end
    
    final_suggestions = suggestions
      .select { |w| w.downcase.start_with?(query.downcase) }
      .map(&:downcase)
      .uniq
      .first(8)

    render json: { queries: final_suggestions }
  end

  def preview
    @user = User.find(params[:id])
    @microposts = @user.microposts.order(created_at: :desc).limit(10)
    
    render layout: false
  end

  private
    #Strong param
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :bio)
    end

    #Confirm the correct user
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

    #Confirm admin user
    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end

end
