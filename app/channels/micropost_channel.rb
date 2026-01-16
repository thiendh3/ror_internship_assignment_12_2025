class MicropostChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'microposts'
  end

  def unsubscribed
    stop_all_streams
  end
end
