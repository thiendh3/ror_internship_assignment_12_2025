module MicropostsHelper
  # Render micropost content with hashtags and mentions as links
  def render_micropost_content(content)
    return '' if content.blank?
    
    # Replace hashtags with links
    content = content.gsub(/#(\w+)/) do |match|
      hashtag = $1
      link_to("##{hashtag}", search_microposts_path(q: "##{hashtag}"), class: 'hashtag-link')
    end
    
    # Replace mentions with links
    content = content.gsub(/@(\w+)/) do |match|
      username = $1
      user = User.find_by(name: username)
      if user
        link_to("@#{username}", user_path(user), class: 'mention-link')
      else
        "@#{username}"
      end
    end
    
    simple_format(content, {}, sanitize: true)
  end
end
