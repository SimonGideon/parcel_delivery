class ApplicationController < ActionController::API
  include Authenticatable
  include CanCan::ControllerAdditions
  include ApiResponse

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from DeliveryRequests::TransitionError, with: :render_conflict
  rescue_from CanCan::AccessDenied, with: :render_access_denied

  private

  def current_ability
    @current_ability ||= Ability.new(current_user || current_driver)
  end

  # Hide resources the principal cannot access (404 instead of 403).
  def render_access_denied(exception)
    subject = exception.subject
    model_name = subject.is_a?(Class) ? subject.model_name : subject.class.model_name

    render_error(message: "Couldn't find #{model_name}", status: :not_found)
  end

  def render_conflict(error)
    render_error(message: error.message, status: :conflict)
  end

  def render_not_found(error)
    render_error(message: error.message, status: :not_found)
  end

  def render_record_invalid(error)
    render_validation_errors(error.record)
  end

  def render_bad_request(error)
    render_error(message: error.message, status: :bad_request)
  end
end
