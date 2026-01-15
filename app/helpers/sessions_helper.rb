module SessionsHelper
  # Logs in the given user.
  def log_in(user)
    session[:user_id] = user.id
  end

  # Remember a user in a persistent session
  def remember(user)
    user.remember
    cookies.permanent.encrypted[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # Return the current logged-in user (if any)
  def current_user
    if (user_id = session[:user_id])
      user = User.find_by(id: user_id)
      session[:current_user_id] = user&.id
      user
    elsif (user_id = cookies.encrypted[:user_id])
      user = User.find_by(id: user_id)
      if user&.authenticated?(:remember, cookies[:remember_token])
        log_in user
        session[:current_user_id] = user.id
        user
      end
    end
  end

  # Return true if the given user is the current user
  def current_user?(user)
    user && user == current_user
  end

  # Return true if user is logged in, false otherwise
  def logged_in?
    !current_user.nil?
  end

  # Forget a persistent session
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # Log out the current user
  def log_out
    forget(current_user)
    session.delete(:user_id)
    session.delete(:current_user_id)
  end

  # Redirect to stored location (intented destionation of non-logging user) (or to the default)
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # Store the URL trying to be accesssed
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
end
