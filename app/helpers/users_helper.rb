module UsersHelper
  # Return the Gravatar for the given user.
  def gravatar_for(user, size: 80)
    gravatar_url = gravatar_url_for(user, size: size)
    image_tag(gravatar_url, alt: user.name, class: 'gravatar')
  end

  # Return gravatar URL string (for JSON responses)
  def gravatar_url_for(user, size: 50)
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
  end
end
