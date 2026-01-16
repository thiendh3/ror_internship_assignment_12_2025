class NotificationsController < ApplicationController
  before_action :logged_in_user

  # GET /notifications
  def index
    @notifications = current_user.notifications.recent.includes(:actor, :notifiable)
    @unread_count = current_user.notifications.unread.count

    respond_to do |format|
      handle_index_response(format)
    end
  end

  # PATCH /notifications/:id/mark_as_read
  def mark_as_read
    @notification = current_user.notifications.find(params[:id])

    respond_to do |format|
      if @notification.mark_as_read!
        handle_mark_as_read_success(format)
      else
        handle_mark_as_read_failure(format)
      end
    end
  end

  # PATCH /notifications/mark_all_as_read
  def mark_all_as_read
    respond_to do |format|
      if current_user.notifications.unread.update_all(read: true)
        handle_mark_all_as_read_success(format)
      else
        handle_mark_all_as_read_failure(format)
      end
    end
  end

  private

  def handle_index_response(format)
    format.json do
      render json: {
        notifications: @notifications.map { |notification| notification_json(notification) },
        unread_count: @unread_count
      }
    end
    format.html
  end

  def handle_mark_as_read_success(format)
    unread_count = current_user.notifications.unread.count
    format.json do
      render json: {
        success: true,
        message: 'Notification marked as read',
        unread_count: unread_count
      }, status: :ok
    end
    format.html { redirect_to notifications_path }
  end

  def handle_mark_as_read_failure(format)
    format.json do
      render json: {
        success: false,
        message: 'Unable to mark as read'
      }, status: :unprocessable_entity
    end
    format.html { redirect_to notifications_path, alert: 'Unable to mark as read' }
  end

  def handle_mark_all_as_read_success(format)
    format.json do
      render json: {
        success: true,
        message: 'All notifications marked as read'
      }, status: :ok
    end
    format.html { redirect_to notifications_path }
  end

  def handle_mark_all_as_read_failure(format)
    format.json do
      render json: {
        success: false,
        message: 'Unable to mark all as read'
      }, status: :unprocessable_entity
    end
    format.html { redirect_to notifications_path, alert: 'Unable to mark all as read' }
  end

  def notification_json(notification)
    {
      id: notification.id,
      message: notification.message,
      action: notification.action,
      read: notification.read,
      created_at: notification.created_at,
      url: notification.url,
      actor: {
        id: notification.actor.id,
        name: notification.actor.name
      },
      notifiable: {
        id: notification.notifiable_id,
        type: notification.notifiable_type
      }
    }
  end
end
