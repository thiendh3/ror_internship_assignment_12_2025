module MicropostsHelper
  def format_micropost_content(content)
    return '' if content.blank?

    formatted = ERB::Util.html_escape(content)

    # Convert @mentions to links
    formatted = formatted.gsub(/@(\w+)/) do |match|
      username = ::Regexp.last_match(1)
      # Try to find by name without spaces or email prefix
      user = User.find_by("LOWER(REPLACE(name, ' ', '')) = ?", username.downcase) ||
             User.find_by("LOWER(SUBSTRING_INDEX(email, '@', 1)) = ?", username.downcase)
      if user
        link_to(match, user_path(user), class: 'mention-link')
      else
        ERB::Util.html_escape(match)
      end
    end

    # Convert hashtags to links
    formatted = formatted.gsub(/#(\w+)/) do |match|
      link_to(match, root_path(hashtag: ::Regexp.last_match(1)), class: 'hashtag-link')
    end

    # rubocop:disable Rails/OutputSafety
    formatted.html_safe # Safe because content is escaped before link generation
    # rubocop:enable Rails/OutputSafety
  end
end
