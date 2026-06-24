# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Parcel Delivery API',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: '/'
        }
      ],
      components: {
        securitySchemes: {
          basic_auth: {
            type: :http,
            scheme: :basic,
            description: <<~DESC.squish
              HTTP Basic authentication. In the Authorize dialog, enter your account
              email as the username and your password. Register first via POST
              /api/v1/users (customers) or POST /api/v1/drivers (drivers). Some
              endpoints accept only one principal type — e.g. POST /delivery_requests
              requires customer credentials, not driver.

              To test with different credentials, click "Logout" in this dialog
              first. Once authorized, Swagger UI hides the username/password
              fields and reuses the saved Authorization header for every
              "Try it out" call until you log out — typing new (even wrong)
              credentials without logging out first has no effect.
            DESC
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
