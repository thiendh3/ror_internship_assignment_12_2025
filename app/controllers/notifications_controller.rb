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
          notifications: @notifications.map do |n|
            n.as_json(
              include: {
                actor: { only: %i[id name email], methods: %i[gravatar_url] },
                notifiable: { only: %i[id content created_at] }
              }
            ).merge(type: n.notification_type)
          end,
          unread_count: @unread_count
        }
      end
    end
  end

  # GET /notifications/unread_count
  def unread_count
    count = current_user.notifications.unread.count
    render json: {
      unread_count: count,
      timestamp: Time.current.to_i
    }
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
    current_user.notifications.unread.find_each do |notification|
      notification.update(read: true)
    end
    render json: { success: true }
  end
end
