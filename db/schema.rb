# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_06_24_112415) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "line1", null: false
    t.string "line2"
    t.string "city", null: false
    t.string "state"
    t.string "postal_code"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delivery_events", force: :cascade do |t|
    t.bigint "delivery_request_id", null: false
    t.integer "event_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_request_id"], name: "index_delivery_events_on_delivery_request_id"
    t.index ["event_type"], name: "index_delivery_events_on_event_type"
  end

  create_table "delivery_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "driver_id"
    t.bigint "pickup_address_id", null: false
    t.bigint "delivery_address_id", null: false
    t.string "package_description", null: false
    t.decimal "package_weight", precision: 8, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_address_id"], name: "index_delivery_requests_on_delivery_address_id"
    t.index ["driver_id"], name: "index_delivery_requests_on_driver_id"
    t.index ["pickup_address_id"], name: "index_delivery_requests_on_pickup_address_id"
    t.index ["status"], name: "index_delivery_requests_on_status"
    t.index ["user_id"], name: "index_delivery_requests_on_user_id"
  end

  create_table "driver_locations", force: :cascade do |t|
    t.bigint "driver_id", null: false
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["driver_id", "recorded_at"], name: "index_driver_locations_on_driver_id_and_recorded_at"
    t.index ["driver_id"], name: "index_driver_locations_on_driver_id"
  end

  create_table "drivers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_drivers_on_email", unique: true
    t.index ["status"], name: "index_drivers_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "delivery_events", "delivery_requests"
  add_foreign_key "delivery_requests", "addresses", column: "delivery_address_id"
  add_foreign_key "delivery_requests", "addresses", column: "pickup_address_id"
  add_foreign_key "delivery_requests", "drivers"
  add_foreign_key "delivery_requests", "users"
  add_foreign_key "driver_locations", "drivers"
end
