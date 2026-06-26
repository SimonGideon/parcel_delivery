class AuthToken
  PURPOSE = :api_auth

  def self.issue(principal)
    verifier.generate(
      { type: principal_type(principal), id: principal.id },
      expires_in: 24.hours,
      purpose: PURPOSE
    )
  end

  def self.principal_for(token)
    payload = verifier.verified(token, purpose: PURPOSE)
    return unless payload.is_a?(Hash)

    case payload["type"] || payload[:type]
    when "user"
      User.find_by(id: payload["id"] || payload[:id])
    when "driver"
      Driver.find_by(id: payload["id"] || payload[:id])
    end
  end

  def self.principal_type(principal)
    case principal
    when Driver then "driver"
    when User then "user"
    else
      raise ArgumentError, "unsupported principal: #{principal.class.name}"
    end
  end
  private_class_method :principal_type

  def self.verifier
    Rails.application.message_verifier(:api_auth_token)
  end
  private_class_method :verifier
end
