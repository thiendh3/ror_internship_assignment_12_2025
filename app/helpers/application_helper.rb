module ApplicationHelper
  REACTION_EMOJIS = {
    'like' => '👍',
    'love' => '❤️',
    'haha' => '😆',
    'wow' => '😮',
    'sad' => '😢',
    'angry' => '😠'
  }.freeze

  # Return the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = 'Ruby on Rails Tutorial Sample App'
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  def reaction_emoji(reaction_type)
    REACTION_EMOJIS[reaction_type] || '👍'
  end

  def reaction_types
    REACTION_EMOJIS
  end
end
