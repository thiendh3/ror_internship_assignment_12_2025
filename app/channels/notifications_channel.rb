class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    # Stream from user-specific notifications channel
    stream_from "notifications_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end
end
