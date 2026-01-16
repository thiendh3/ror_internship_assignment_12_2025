# frozen_string_literal: true

class MicropostsChannel < ApplicationCable::Channel
  def subscribed
    # Stream for all micropost updates (posts, reactions, comments, shares)
    stream_for 'feed'
  end

  def unsubscribed
    stop_all_streams
  end
end
