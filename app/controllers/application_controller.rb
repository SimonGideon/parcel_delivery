class ApplicationController < ActionController::API
  include Authenticatable

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from DeliveryRequests::TransitionError, with: :render_conflict

  private

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      next_page: collection.next_page,
      prev_page: collection.prev_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end

  def render_conflict(error)
    render json: {
      error: {
        code: "conflict",
        message: error.message
      }
    }, status: :conflict
  end

  def render_not_found(error)
    render json: {
      error: {
        code: "not_found",
        message: error.message
      }
    }, status: :not_found
  end

  def render_unprocessable_entity(error)
    render json: {
      error: {
        code: "unprocessable_entity",
        message: error.record.errors.full_messages.to_sentence,
        details: error.record.errors.to_hash
      }
    }, status: :unprocessable_entity
  end

  def render_bad_request(error)
    render json: {
      error: {
        code: "bad_request",
        message: error.message
      }
    }, status: :bad_request
  end
end
