# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :logged_in_user

  def index
    @current_tab = params[:tab] || 'all'
    @notifications = case @current_tab
                     when 'read'
                       current_user.notifications.where(read: true).recent.limit(20)
                     when 'unread'
                       current_user.notifications.unread.recent.limit(20)
                     else
                       current_user.notifications.recent.limit(20)
                     end
    respond_to do |format|
      format.html
      format.json { render json: { notifications: notifications_json } }
    end
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.update(read: true)

    respond_to do |format|
      format.html { redirect_to notification.target_url }
      format.json { render json: { success: true, target_url: notification.target_url } }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)
    respond_to do |format|
      format.html { redirect_to notifications_path(tab: 'read'), notice: 'All notifications marked as read' }
      format.json { head :ok }
    end
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
        actor: n.actor ? {
          id: n.actor.id,
          name: n.actor.name,
          email: n.actor.email,
          avatar_url: gravatar_url(n.actor)
        } : nil,
        message: n.message,
        target_url: n.target_url,
        created_at: n.created_at,
        read: n.read
      }
    end
  end

  def gravatar_url(user, size = 40)
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=identicon"
  end
end
