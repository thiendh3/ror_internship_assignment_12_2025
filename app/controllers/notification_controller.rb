class NotificationsController < ApplicationController
  before_action :logged_in_user

  def index
    @notifications = current_user.notifications.includes(:actor, :notifiable).order(created_at: :desc).limit(10)
    
    respond_to do |format|
      format.html 
      format.js   
    end
  end

  def mark_as_read
    current_user.notifications.where(read_at: nil).update_all(read_at: Time.zone.now)
    head :no_content
  end
end