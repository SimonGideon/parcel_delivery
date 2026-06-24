module ApiResponse
  extend ActiveSupport::Concern

  def render_success(data: nil, message: "Success", meta: nil, status: :ok)
    render json: {
      success: true,
      message: message,
      data: data,
      meta: meta
    }, status: status
  end

  def render_error(message: "Error", errors: [], status: :unprocessable_content)
    render json: {
      success: false,
      message: message,
      errors: errors
    }, status: status
  end

  # errors: [{ field:, message:, code: }, ...] -- built from an
  # ActiveModel::Errors collection, e.g. `render_validation_errors(user)`.
  def render_validation_errors(record, message: "Validation failed", status: :unprocessable_content)
    render_error(message: message, errors: format_validation_errors(record), status: status)
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      next_page: collection.next_page,
      prev_page: collection.prev_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end

  private

  def format_validation_errors(record)
    record.errors.map do |error|
      {
        field: error.attribute.to_s,
        message: error.message,
        code: error.type.to_s
      }
    end
  end
end
