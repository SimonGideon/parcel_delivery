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
      tags: [
        {
          name: 'Authorization',
          description: 'Register users and drivers, then log in to get a bearer token for protected endpoints.'
        },
        {
          name: 'Delivery Requests',
          description: 'Create, view, list, cancel, accept, and reject parcel delivery requests.'
        },
        {
          name: 'Delivery Events',
          description: 'View delivery request lifecycle history.'
        },
        {
          name: 'Driver Locations',
          description: 'Driver location reporting.'
        },
        {
          name: 'Reference Data',
          description: 'Countries and counties used by address forms.'
        },
        {
          name: 'Health',
          description: 'Service health checks.'
        }
      ],
      servers: [
        {
          url: '/'
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :signed_token,
            description: <<~DESC.squish
              Log in via POST /api/v1/login with username (email) and password,
              copy the returned token, then paste only the token value here.
              Swagger UI will send it as Authorization: Bearer <token>.
              Some endpoints accept only one principal type — e.g.
              POST /delivery_requests requires a customer token, not a driver token.
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
