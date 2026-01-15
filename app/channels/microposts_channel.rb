class MicropostsChannel < ApplicationCable::Channel
  def subscribed
    # Stream from microposts feed channel for current user's feed
    stream_from "microposts_feed_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end
end
