# frozen_string_literal: true

class MicropostsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'microposts:feed'
  end

  def unsubscribed
    stop_all_streams
  end
end
