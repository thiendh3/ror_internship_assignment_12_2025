module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if (user_id = request.session[:user_id])
        verified_user = User.find_by(id: user_id)
      elsif (user_id = cookies.encrypted[:user_id])
        user = User.find_by(id: user_id)
        if user && user.authenticated?(:remember, cookies[:remember_token])
          verified_user = user
        end
      end

      verified_user || reject_unauthorized_connection
    end
  end
end