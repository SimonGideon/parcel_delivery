module Authenticatable
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  private

  # Authenticates a customer via HTTP Basic (email:password). Sets current_user.
  def authenticate_user!
    authenticate_with_http_basic do |email, password|
      user = User.find_by(email: email.to_s.downcase)
      user&.authenticate(password) && (@current_user = user)
    end

    render_unauthorized unless @current_user
  end

  # Authenticates a driver via HTTP Basic (email:password). Sets current_driver.
  def authenticate_driver!
    authenticate_with_http_basic do |email, password|
      driver = Driver.find_by(email: email.to_s.downcase)
      driver&.authenticate(password) && (@current_driver = driver)
    end

    render_unauthorized unless @current_driver
  end

  # Some endpoints (viewing a delivery request, its event history) are
  # readable by either the customer who owns it or the driver assigned to
  # it. HTTP Basic carries one credential pair, so try both principal tables.
  def authenticate_user_or_driver!
    authenticate_with_http_basic do |email, password|
      email = email.to_s.downcase
      user = User.find_by(email: email)
      next true if user&.authenticate(password) && (@current_user = user)

      driver = Driver.find_by(email: email)
      driver&.authenticate(password) && (@current_driver = driver)
    end

    render_unauthorized unless @current_user || @current_driver
  end

  def current_user
    @current_user
  end

  def current_driver
    @current_driver
  end

  def render_unauthorized
    response.set_header("WWW-Authenticate", 'Basic realm="Application"')
    render json: {
      error: {
        code: "unauthorized",
        message: "Invalid or missing credentials"
      }
    }, status: :unauthorized
  end
end
