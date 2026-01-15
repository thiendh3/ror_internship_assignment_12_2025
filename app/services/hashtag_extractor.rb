class HashtagExtractor
  HASHTAG_REGEX = /#(\w+)/

  class << self
    # Extract hashtags from content and associate with micropost
    def extract_and_associate(micropost)
      return unless micropost.content.present?

      # Extract hashtag names from content
      hashtag_names = extract_hashtags(micropost.content)

      # Clear existing associations
      micropost.micropost_hashtags.destroy_all if micropost.persisted?

      # Create or find hashtags and associate with micropost
      hashtag_names.each do |name|
        hashtag = Hashtag.find_or_create_by(name: name.downcase)
        micropost.hashtags << hashtag unless micropost.hashtags.include?(hashtag)
      end
    end

    # Extract hashtag names from content
    def extract_hashtags(content)
      content.scan(HASHTAG_REGEX).flatten.uniq
    end
  end
end
