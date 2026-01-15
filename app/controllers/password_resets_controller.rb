class PasswordResetsController < ApplicationController
  before_action :get_user, only: %i[edit update]
  before_action :valid_user, only: %i[edit update]
  before_action :check_expiration, only: %i[edit update] # Filter for expired request

  def new; end

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = 'Email sent with password reset instructions'
      redirect_to root_url
    else
      flash.now[:danger] = 'Email address is not found'
      render 'new'
    end
  end

  def edit; end

  def update
    if params[:user][:password].empty? # Check empty password change
      @user.errors.add(:password, "can't be empty")
      render 'edit'
    elsif @user.update(user_params) # Successful change and auto login
      log_in @user
      @user.update_attribute(:reset_digest, nil)
      flash[:success] = 'Password has been reset.'
      redirect_to @user
    else # Weak password or other errors.
      render 'edit'
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  # Before filter
  def get_user
    @user = User.find_by(email: params[:email])
  end

  # Confirm valid user
  def valid_user
    return if @user && @user.activated? && @user.authenticated?(:reset, params[:id])

    flash[:danger] = 'Password reset has expired due to password has been reset so far.' if @user.reset_digest.nil?
    redirect_to root_url
  end

  # Check expiration of reset token
  def check_expiration
    return unless @user.password_reset_expired?

    flash[:danger] = 'Password reset has expired.'
    redirect_to new_password_reset_url
  end
end
