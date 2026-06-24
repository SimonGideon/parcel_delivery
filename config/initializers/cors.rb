# Be sure to restart your server when you modify this file.

# Allowed origins come from CORS_ALLOWED_ORIGINS (comma-separated), e.g.
#   CORS_ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com
# Defaults to "*" so the API is easy to evaluate out of the box. Since auth
# uses Authorization headers, not cookies, a wildcard origin
# does not carry the same credential-leak risk it would with cookie auth --
# but set CORS_ALLOWED_ORIGINS explicitly before exposing this to real traffic.
allowed_origins = ENV.fetch("CORS_ALLOWED_ORIGINS", "*").split(",").map(&:strip)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[X-Request-Id]
  end
end
