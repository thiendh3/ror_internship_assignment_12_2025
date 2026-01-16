class MicropostBroadcastJob < ApplicationJob
  queue_as :default

  def perform(micropost)
    # Broadcast to all followers of the micropost author
    micropost.user.followers.each do |follower|
      ActionCable.server.broadcast(
        "microposts_feed_#{follower.id}",
        new_micropost_payload(micropost)
      )
    end
  end

  private

  def new_micropost_payload(micropost)
    {
      action: 'new_micropost',
      micropost: micropost_broadcast_data(micropost)
    }
  end

  def micropost_broadcast_data(micropost)
    {
      id: micropost.id,
      content: micropost.content,
      privacy: micropost.privacy,
      likes_count: micropost.likes_count,
      comments_count: micropost.comments_count,
      created_at: micropost.created_at,
      user: {
        id: micropost.user.id,
        name: micropost.user.name
      },
      hashtags: micropost.hashtags.pluck(:name)
    }
  end
end
