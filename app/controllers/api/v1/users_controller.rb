module Api
  module V1
    class UsersController < ApplicationController
      # Registration is the one endpoint a customer can hit before they have
      # credentials, so it intentionally skips authenticate_user!.

      def create
        user = User.new(user_params)

        if user.save
          render_success(
            data: UserSerializer.new(user).as_json,
            message: "User created successfully",
            status: :created
          )
        else
          render_validation_errors(user)
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :phone)
      end
    end
  end
end
