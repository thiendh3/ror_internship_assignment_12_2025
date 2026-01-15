module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      user_id = request.session[:user_id] || cookies.encrypted[:user_id]
      return reject_unauthorized_connection unless user_id

      verified_user = User.find_by(id: user_id)
      return reject_unauthorized_connection unless verified_user

      verify_user_authentication(verified_user)
    end

    def verify_user_authentication(user)
      return user if session_authenticated?

      verify_remember_token(user)
    end

    def session_authenticated?
      request.session[:user_id].present?
    end

    def verify_remember_token(user)
      if cookies[:remember_token] && user.authenticated?(:remember, cookies[:remember_token])
        user
      else
        reject_unauthorized_connection
      end
    end
  end
end
