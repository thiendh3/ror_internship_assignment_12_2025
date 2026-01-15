class UsersController < ApplicationController
  require 'will_paginate/array'

  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :set_user,       only: [:show, :edit, :edit_modal, :update, :destroy, :following, :followers, :preview]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy

  def index
    @search = UserSearch.new(params, current_user)
    result = @search.results

    @users = WillPaginate::Collection.create(result.page, result.per_page, result.total_count) do |pager|
      pager.replace(result.records)
    end
    
    @total_found = result.total_count
    @filter_type = params[:filter]
  end

  def show
    @microposts = @user.microposts.paginate(page: params[:page])
    
    unless @user.activated?
      redirect_to root_url and return 
    end
    
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
  end

  def edit_modal
    render layout: false
  end

  def update
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

  def destroy
    @user.destroy
    flash[:success] = "User is deleted!"
    redirect_to users_url
  end

  def following
    @title = "Following"
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "Followers"
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
    
    final_suggestions = filter_autocomplete_suggestions(search.results.records, query)

    render json: { queries: final_suggestions }
  end

  def preview
    @microposts = @user.microposts.order(created_at: :desc).limit(10)
    render layout: false
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :bio)
    end

    def set_user
      @user = User.find(params[:id])
    end

    def correct_user
      redirect_to(root_url) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_url) unless current_user.admin?
    end

    def filter_autocomplete_suggestions(records, query)
      suggestions = records.flat_map do |user|
        if current_user&.admin? && params[:search_field] == 'email'
          [user.email]
        else
          user.name.split(/\s+/)
        end
      end

      suggestions
        .select { |w| w.downcase.start_with?(query.downcase) }
        .map(&:downcase)
        .uniq
        .first(8)
    end
end