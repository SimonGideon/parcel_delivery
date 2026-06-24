# Parcel Delivery Backend

Rails API for parcel delivery. Customers create delivery requests, drivers accept or reject jobs, and every status change is saved as an audit event.

## Stack

- Ruby `3.2.2`
- Rails `7.1.5` API-only
- PostgreSQL with UUID primary keys
- CanCanCan authorization
- bcrypt authentication
- Kaminari pagination
- rswag Swagger docs
- RSpec, FactoryBot, Faker

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

- App: `http://localhost:3000`
- Docs: `http://localhost:3000/docs`
- Seeds: Kenya counties and neighboring countries

## Tests

```bash
bundle exec rspec
```

## Authentication

- Register a customer: `POST /api/v1/users`
- Register a driver: `POST /api/v1/drivers`
- Login: `POST /api/v1/login`
- Use the returned token:

```http
Authorization: Bearer <token>
```

- Token expires after 24 hours.
- `principal_type` tells the API whether the caller is a `user` or `driver`.
- HTTP Basic auth is still available for quick manual testing.

## Core Models

- `User`: customer who creates delivery requests
- `Driver`: delivery worker with availability status
- `Address`: pickup or drop-off location
- `DriverLocation`: latest GPS location for matching
- `DeliveryRequest`: main delivery record
- `DeliveryEvent`: audit log for lifecycle changes

## Delivery Flow

```text
pending -> finding_driver -> assigned -> accepted -> picked_up -> in_transit -> delivered
```

Other actions:

- Customer can cancel before pickup.
- Driver can reject an assigned request.
- Rejected requests return to `finding_driver`.
- Drivers who rejected a request are skipped in the next match.

## Delivery Request Lists

- Customer endpoint: `GET /api/v1/customer/delivery_requests`
- Driver endpoint: `GET /api/v1/driver/delivery_requests`

Supports:

- Pagination: `page`, `per_page`
- Status filtering: `status`
- Driver filtering: `driver_id`
- Date filtering: `created_from`, `created_to`
- Search: `q`
- Sorting: `sort_by`, `sort_direction`

## API Behavior

- All responses use one JSON envelope.
- Validation errors return clear field messages.
- Unauthorized records return `404` to avoid exposing private IDs.
- Swagger docs are generated from request specs.

## Driver Matching

- Matching runs from delivery events.
- `AssignNearestDriverJob` finds available drivers.
- Latest driver locations are fetched efficiently with PostgreSQL `DISTINCT ON`.
- Distance is calculated with Haversine logic.
