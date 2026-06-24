module DeliveryRequestAuthorizable
  extend ActiveSupport::Concern

  private

  # Hides existence of requests the current principal can't see, per the
  # security checklist convention of returning 404 instead of 403.
  def authorize_delivery_request_access!(delivery_request)
    return if current_user && delivery_request.user_id == current_user.id
    return if current_driver && delivery_request.driver_id == current_driver.id

    render json: {
      error: { code: "not_found", message: "Couldn't find DeliveryRequest" }
    }, status: :not_found
  end
end
