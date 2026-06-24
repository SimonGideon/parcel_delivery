module BasicAuthHelper
  def basic_auth_headers(email, password)
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(email, password) }
  end

  def bearer_auth_headers(principal)
    { "Authorization" => "Bearer #{AuthToken.issue(principal)}" }
  end
end

RSpec.configure do |config|
  config.include BasicAuthHelper, type: :request
end
