module Api
  module V1
    class SessionsController < ApplicationController
      # Exchanges email/password credentials for a signed bearer token that
      # Swagger UI can store via its Authorize button.
      def create
        principal = authenticate_login_principal
        return render_invalid_login unless principal

        render_success(data: login_payload(principal), message: "Login successful")
      end

      private

      def login_payload(principal)
        if principal.is_a?(User)
          {
            type: "user",
            token: AuthToken.issue(principal),
            token_type: "Bearer",
            expires_in: 24.hours.to_i,
            principal: UserSerializer.new(principal).as_json
          }
        else
          {
            type: "driver",
            token: AuthToken.issue(principal),
            token_type: "Bearer",
            expires_in: 24.hours.to_i,
            principal: DriverSerializer.new(principal).as_json
          }
        end
      end

      def render_invalid_login
        render_error(message: "Invalid username or password", status: :unauthorized)
      end

      def authenticate_login_principal
        email = login_params[:username].to_s.downcase
        password = login_params[:password]
        principal_type = login_params[:principal_type].presence

        return authenticate_user(email, password) if principal_type == "user"
        return authenticate_driver(email, password) if principal_type == "driver"

        authenticate_user(email, password) || authenticate_driver(email, password)
      end

      def authenticate_user(email, password)
        user = User.find_by(email: email)
        user if user&.authenticate(password)
      end

      def authenticate_driver(email, password)
        driver = Driver.find_by(email: email)
        driver if driver&.authenticate(password)
      end

      def login_params
        params.require(:login).permit(:username, :password, :principal_type)
      end
    end
  end
end
