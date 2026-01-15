class NotificationsController < ApplicationController
  before_action :logged_in_user

  # GET /notifications
  def index
    @notifications = current_user.notifications.recent.includes(:actor, :notifiable)
    @unread_count = current_user.notifications.unread.count

    respond_to do |format|
      format.json {
        render json: {
          notifications: @notifications.map { |notification|
            {
              id: notification.id,
              message: notification.message,
              action: notification.action,
              read: notification.read,
              created_at: notification.created_at,
              actor: {
                id: notification.actor.id,
                name: notification.actor.name
              },
              notifiable: {
                id: notification.notifiable_id,
                type: notification.notifiable_type
              }
            }
          },
          unread_count: @unread_count
        }
      }
      format.html
    end
  end

  # PATCH /notifications/:id/mark_as_read
  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    
    respond_to do |format|
      if @notification.mark_as_read!
        unread_count = current_user.notifications.unread.count
        format.json {
          render json: {
            success: true,
            message: 'Notification marked as read',
            unread_count: unread_count
          }, status: :ok
        }
        format.html { redirect_to notifications_path }
      else
        format.json {
          render json: {
            success: false,
            message: 'Unable to mark as read'
          }, status: :unprocessable_entity
        }
        format.html { redirect_to notifications_path, alert: 'Unable to mark as read' }
      end
    end
  end

  # PATCH /notifications/mark_all_as_read
  def mark_all_as_read
    respond_to do |format|
      if current_user.notifications.unread.update_all(read: true)
        format.json {
          render json: {
            success: true,
            message: 'All notifications marked as read'
          }, status: :ok
        }
        format.html { redirect_to notifications_path }
      else
        format.json {
          render json: {
            success: false,
            message: 'Unable to mark all as read'
          }, status: :unprocessable_entity
        }
        format.html { redirect_to notifications_path, alert: 'Unable to mark all as read' }
      end
    end
  end
end
