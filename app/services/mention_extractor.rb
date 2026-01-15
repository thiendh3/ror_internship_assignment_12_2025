class MentionExtractor
  MENTION_REGEX = /@(\w+)/

  class << self
    # Extract mentions from content and create notifications
    def extract_and_notify(micropost)
      return unless micropost.content.present?

      # Extract usernames from content
      usernames = extract_mentions(micropost.content)

      # Find users and create notifications
      usernames.each do |username|
        mentioned_user = User.find_by(name: username)
        next unless mentioned_user
        next if mentioned_user.id == micropost.user_id # Don't notify self

        NotificationService.create_mention_notification(
          micropost.user,
          mentioned_user,
          micropost
        )
      end
    end

    # Extract usernames from content
    def extract_mentions(content)
      content.scan(MENTION_REGEX).flatten.uniq
    end
  end
end
