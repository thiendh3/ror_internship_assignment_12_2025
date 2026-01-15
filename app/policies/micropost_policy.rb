class MicropostPolicy
  attr_reader :user, :micropost

  def initialize(user, micropost)
    @user = user
    @micropost = micropost
  end

  # Check if user can view this micropost
  def show?
    case micropost.privacy
    when 'public_post'
      true
    when 'followers_only'
      user && (micropost.user == user || user.following?(micropost.user))
    when 'private_post'
      user && micropost.user == user
    else
      false
    end
  end

  # Check if user can edit this micropost
  def update?
    user && micropost.user == user
  end

  # Check if user can delete this micropost
  def destroy?
    user && (micropost.user == user || user.admin?)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # Return microposts that user can see
    def resolve
      if user.nil?
        # Anonymous users can only see public posts
        scope.where(privacy: 'public_post')
      else
        # Logged in users can see:
        # - All public posts
        # - Followers-only posts from users they follow
        # - Their own private posts
        scope.where(
          'privacy = ? OR (privacy = ? AND user_id IN (?)) OR user_id = ?',
          Micropost.privacies[:public_post],
          Micropost.privacies[:followers_only],
          user.following.pluck(:id),
          user.id
        )
      end
    end
  end
end
