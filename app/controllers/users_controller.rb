class UsersController < ApplicationController
  require 'will_paginate/array'

  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit, :update]
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
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
      #log_in @user
      #flash[:success] = "Welcome to the Sample App!"
      #redirect_to @user
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
      flash[:success] = "Profile is updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def index
    page = params[:page] || 1
    per_page = 30

    if params[:query].present?
      is_admin = current_user&.admin?
      result = SolrService.search(params[:query], page: page, per_page: per_page, is_admin: is_admin)

      users_by_id = User.where(id: result[:ids]).index_by(&:id)
      ordered_users = result[:ids].map { |id| users_by_id[id.to_i] }.compact

      @users = WillPaginate::Collection.create(page, per_page, result[:total]) do |pager|
        pager.replace(ordered_users)
      end

      @is_search_mode = true
    else
      @users = User.where(activated: true).paginate(page: params[:page], per_page: per_page)
      @is_search_mode = false
    end
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

  private
    #Strong param
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    #Before filter

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
