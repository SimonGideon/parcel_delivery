module Authenticatable
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  private

  # Authenticates a customer via bearer token or HTTP Basic (email:password).
  def authenticate_user!
    principal = bearer_principal
    @current_user = principal if customer_principal?(principal)
    @current_user ||= authenticate_basic_user

    render_unauthorized unless @current_user
  end

  # Authenticates a driver via bearer token or HTTP Basic (email:password).
  def authenticate_driver!
    principal = bearer_principal
    @current_driver = principal if principal.is_a?(Driver)
    @current_driver ||= authenticate_basic_driver

    render_unauthorized unless @current_driver
  end

  # Some endpoints (viewing a delivery request, its event history) are
  # readable by either the customer who owns it or the driver assigned to
  # it. Bearer tokens encode the principal type; Basic tries both tables.
  def authenticate_user_or_driver!
    case (principal = bearer_principal)
    when Driver
      @current_driver = principal
    when User
      @current_user = principal
    end

    authenticate_basic_user_or_driver! unless @current_user || @current_driver

    render_unauthorized unless @current_user || @current_driver
  end

  def current_user
    @current_user
  end

  def current_driver
    @current_driver
  end

  # Omit WWW-Authenticate so browsers don't show a native Basic-auth dialog
  # on 401; API clients (Swagger UI, curl -u) send Authorization explicitly.
  def render_unauthorized
    message = if bearer_credentials_sent?
                "Invalid or expired bearer token"
              elsif basic_credentials_sent?
                "Invalid credentials for this endpoint"
              else
                "Missing Authorization header — log in and use the returned bearer token in Swagger"
              end

    render_error(message: message, status: :unauthorized)
  end

  def basic_credentials_sent?
    request.authorization.present? &&
      request.authorization.split(" ", 2).first.casecmp("basic").zero?
  end

  def bearer_credentials_sent?
    bearer_token.present?
  end

  def bearer_principal
    return @bearer_principal if defined?(@bearer_principal)

    @bearer_principal = bearer_token.present? ? AuthToken.principal_for(bearer_token) : nil
  end

  def bearer_token
    scheme, token = request.authorization.to_s.split(" ", 2)
    return unless scheme&.casecmp("bearer")&.zero?

    token
  end

  def authenticate_basic_user
    authenticate_with_http_basic do |email, password|
      user = User.customers.find_by(email: email.to_s.downcase)
      user if user&.authenticate(password)
    end
  end

  def authenticate_basic_driver
    authenticate_with_http_basic do |email, password|
      driver = Driver.find_by(email: email.to_s.downcase)
      driver if driver&.authenticate(password)
    end
  end

  def authenticate_basic_user_or_driver!
    authenticate_with_http_basic do |email, password|
      email = email.to_s.downcase
      user = User.customers.find_by(email: email)

      if user&.authenticate(password)
        @current_user = user
        next true
      end

      driver = Driver.find_by(email: email)
      driver&.authenticate(password) && (@current_driver = driver)
    end
  end

  def customer_principal?(principal)
    principal.is_a?(User) && !principal.is_a?(Driver)
  end
end
