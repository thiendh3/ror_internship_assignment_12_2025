module MicropostsHelper
  def format_micropost_content(content)
    return '' if content.blank?
    
    formatted = h(content)
    
    # Convert @mentions to links
    formatted = formatted.gsub(/@(\w+)/) do |match|
      username = $1
      # Try to find by name without spaces or email prefix
      user = User.find_by("LOWER(REPLACE(name, ' ', '')) = ?", username.downcase) ||
             User.find_by("LOWER(SUBSTRING_INDEX(email, '@', 1)) = ?", username.downcase)
      
      if user
        link_to(match, user_path(user), class: 'mention-link')
      else
        match
      end
    end
    
    # Convert hashtags to links
    formatted = formatted.gsub(/#(\w+)/) do |match|
      link_to(match, root_path(hashtag: $1), class: 'hashtag-link')
    end
    
    formatted.html_safe
  end
end
