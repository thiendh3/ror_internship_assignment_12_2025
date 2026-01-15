class NotificationsController < ApplicationController
  before_action :logged_in_user
  
  # GET /notifications
  def index
    @notifications = current_user.notifications.recent.limit(50)
    @unread_count = current_user.notifications.unread.count
    
    respond_to do |format|
      format.html
      format.json do
        render json: {
          notifications: @notifications.as_json(
            include: {
              actor: { only: [:id, :name, :email], methods: [:gravatar_url] },
              notifiable: { only: [:id, :content, :created_at] }
            }
          ),
          unread_count: @unread_count
        }
      end
    end
  end
  
  # GET /notifications/unread_count
  def unread_count
    count = current_user.notifications.unread.count
    render json: { unread_count: count }
  end
  
  # PUT /notifications/:id/mark_as_read
  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!
    
    render json: { success: true, notification: notification }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Notification not found' }, status: :not_found
  end
  
  # PUT /notifications/mark_all_as_read
  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)
    render json: { success: true }
  end
end
