class Admin::UsersController < ApplicationController
  before_action :logged_in_user
  before_action :admin_user
  before_action :set_user, only: %i[edit update destroy]

  def index
    @users = User.where(activated: true).paginate(page: params[:page], per_page: 30)
  end

  def edit
    # Edit form will be rendered
  end

  def update
    if @user.update(user_params)
      flash[:success] = 'User updated successfully'
      redirect_to admin_users_path
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    flash[:success] = 'User deleted'
    redirect_to admin_users_path
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :admin, :activated)
  end

  def admin_user
    redirect_to(root_url) unless current_user&.admin?
  end
end
