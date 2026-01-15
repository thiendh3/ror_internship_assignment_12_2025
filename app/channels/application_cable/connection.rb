module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        user_id = request.session[:user_id] || cookies.encrypted[:user_id]
        
        if user_id && (verified_user = User.find_by(id: user_id))
          if request.session[:user_id].nil? && cookies[:remember_token]
            if verified_user.authenticated?(:remember, cookies[:remember_token])
              verified_user
            else
              reject_unauthorized_connection
            end
          else
            verified_user
          end
        else
          reject_unauthorized_connection
        end
      end
  end
end
