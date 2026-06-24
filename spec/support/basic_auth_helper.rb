module BasicAuthHelper
  def basic_auth_headers(email, password)
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(email, password) }
  end
end

RSpec.configure do |config|
  config.include BasicAuthHelper, type: :request
end
