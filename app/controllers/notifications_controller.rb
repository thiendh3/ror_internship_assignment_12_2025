# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :logged_in_user

  def index
    @current_tab = params[:tab] || 'unread'
    @notifications = if @current_tab == 'read'
                       current_user.notifications.where(read: true).recent.limit(20)
                     else
                       current_user.notifications.unread.recent.limit(20)
                     end
    respond_to do |format|
      format.html
      format.json { render json: notifications_json }
    end
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.update(read: true)
    if notification.actor
      redirect_to user_path(notification.actor)
    else
      redirect_to notifications_path
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)
    head :ok
  end

  def unread_count
    render json: { count: current_user.notifications.unread.count }
  end

  private

  def notifications_json
    @notifications.map do |n|
      {
        id: n.id,
        type: n.notification_type,
        actor: {
          id: n.actor&.id,
          name: n.actor&.name,
          email: n.actor&.email
        },
        message: notification_message(n),
        created_at: n.created_at,
        read: n.read
      }
    end
  end

  def notification_message(notification)
    actor_name = notification.actor&.name || 'Someone'
    case notification.notification_type
    when 'follow'
      "#{actor_name} started following you"
    when 'unfollow'
      "#{actor_name} unfollowed you"
    else
      'You have a new notification'
    end
  end
end
