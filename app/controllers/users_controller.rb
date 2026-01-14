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
    
    # Logic for Filters (unchanged)
    @filter_type = params[:filter] || 'all'
    unless current_user.admin?
      @filter_type = 'all' if ['activated', 'not_activated'].include?(@filter_type)
    end

    # Solr Search
    is_admin = current_user&.admin?
    query = params[:query] || ""

    @search_field = if is_admin && params[:search_field] == 'email'
                      'email'
                    else
                      'name'
                    end

    count_filter = {
      field: params[:count_field],       # 'followers' or 'following'
      operator: params[:count_operator], # '>' or '<'
      value: params[:count_value]        # e.g., '50'
    }

    result = SolrService.search(
      query, 
      page: page, 
      per_page: per_page, 
      is_admin: is_admin,
      filter_type: @filter_type,
      following_ids: current_user.following.ids,
      current_user_id: current_user.id,
      search_field: @search_field,
      count_filter: count_filter
    )

    # Reorder results
    users_by_id = User.where(id: result[:ids]).index_by(&:id)
    ordered_users = result[:ids].map { |id| users_by_id[id.to_i] }.compact

    # Create paginated collection
    @users = WillPaginate::Collection.create(page, per_page, result[:total]) do |pager|
      pager.replace(ordered_users)
    end
    
    # Store total found count for the view
    @total_found = result[:total]

    @is_search_mode = true
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
    query = params[:query]
    if query.blank?
      render json: { queries: [], users: [] }
      return
    end

    search_field = (current_user&.admin? && params[:search_field] == 'email') ? 'email' : 'name'

    # Fetch more results now that we have a scrollbar
    result = SolrService.search(
      query, 
      page: 1, 
      per_page: 15, # Increased limit
      is_admin: current_user&.admin?,
      search_field: search_field
    )

    # 1. Generate Query Autocomplete (The "Search for..." strings)
    # We extract unique names/emails from the Solr result IDs to suggest terms
    users = User.where(id: result[:ids])
    suggested_queries = users.map { |u| search_field == 'email' ? u.email : u.name }.uniq.first(5)

    # 2. Generate User Suggestions (The "Instant Results" objects)
    users_by_id = users.index_by(&:id)
    ordered_users = result[:ids].map { |id| users_by_id[id.to_i] }.compact

    user_suggestions = ordered_users.map do |u|
      data = {
        id: u.id,
        name: u.name,
        gravatar_url: "https://secure.gravatar.com/avatar/#{Digest::MD5::hexdigest(u.email.downcase)}?s=50",
        followers_count: u.followers.count,
        following_count: u.following.count,
        url: user_path(u)
      }
      data[:email] = u.email if current_user&.admin?
      data
    end

    render json: { queries: suggested_queries, users: user_suggestions }
  end

  private
    #Strong param
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
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
