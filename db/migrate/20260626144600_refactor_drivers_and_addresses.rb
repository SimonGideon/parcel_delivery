class RefactorDriversAndAddresses < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :type, :string
    add_column :users, :role, :integer, null: false, default: 0
    add_column :users, :status, :integer, null: false, default: 0
    add_index :users, :type
    add_index :users, :role
    add_index :users, :status

    execute <<~SQL.squish
      INSERT INTO users (id, name, email, password_digest, phone, type, role, status, created_at, updated_at)
      SELECT id, name, email, password_digest, phone, 'Driver', 1, status, created_at, updated_at
      FROM drivers
      ON CONFLICT (email) DO NOTHING
    SQL

    remove_foreign_key :delivery_requests, :drivers
    remove_foreign_key :driver_locations, :drivers
    add_foreign_key :delivery_requests, :users, column: :driver_id
    add_foreign_key :driver_locations, :users, column: :driver_id

    add_column :delivery_requests, :pickup_address_snapshot, :jsonb, null: false, default: {}
    add_column :delivery_requests, :delivery_address_snapshot, :jsonb, null: false, default: {}

    copy_address_snapshot(:pickup_address_snapshot, :pickup_address_id)
    copy_address_snapshot(:delivery_address_snapshot, :delivery_address_id)

    remove_foreign_key :delivery_requests, column: :pickup_address_id
    remove_foreign_key :delivery_requests, column: :delivery_address_id
    remove_index :delivery_requests, column: :pickup_address_id
    remove_index :delivery_requests, column: :delivery_address_id
    remove_column :delivery_requests, :pickup_address_id
    remove_column :delivery_requests, :delivery_address_id

    rename_column :delivery_requests, :pickup_address_snapshot, :pickup_address
    rename_column :delivery_requests, :delivery_address_snapshot, :delivery_address

    drop_table :addresses
    drop_table :drivers
  end

  def down
    create_table :drivers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :phone
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :drivers, :email, unique: true
    add_index :drivers, :status

    execute <<~SQL.squish
      INSERT INTO drivers (id, name, email, password_digest, phone, status, created_at, updated_at)
      SELECT id, name, email, password_digest, phone, status, created_at, updated_at
      FROM users
      WHERE type = 'Driver'
    SQL

    create_table :addresses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :postal_code
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.string :nearest_town
      t.uuid :country_id
      t.uuid :county_id
      t.string :building_name
      t.string :floor
      t.string :door
      t.text :instructions
      t.timestamps
    end
    add_index :addresses, :country_id
    add_index :addresses, :county_id
    add_foreign_key :addresses, :countries
    add_foreign_key :addresses, :counties

    add_reference :delivery_requests, :pickup_address, type: :uuid, foreign_key: { to_table: :addresses }
    add_reference :delivery_requests, :delivery_address, type: :uuid, foreign_key: { to_table: :addresses }

    restore_address_table(:pickup_address_id, :pickup_address)
    restore_address_table(:delivery_address_id, :delivery_address)

    change_column_null :delivery_requests, :pickup_address_id, false
    change_column_null :delivery_requests, :delivery_address_id, false
    remove_column :delivery_requests, :pickup_address
    remove_column :delivery_requests, :delivery_address

    remove_foreign_key :delivery_requests, column: :driver_id
    remove_foreign_key :driver_locations, column: :driver_id
    add_foreign_key :delivery_requests, :drivers
    add_foreign_key :driver_locations, :drivers

    remove_index :users, :status
    remove_index :users, :role
    remove_index :users, :type
    execute "DELETE FROM users WHERE type = 'Driver'"
    remove_column :users, :status
    remove_column :users, :role
    remove_column :users, :type
  end

  private

  def copy_address_snapshot(target_column, source_column)
    execute <<~SQL.squish
      UPDATE delivery_requests
      SET #{target_column} = jsonb_strip_nulls(jsonb_build_object(
        'line1', addresses.line1,
        'line2', addresses.line2,
        'city', addresses.city,
        'county_id', addresses.county_id,
        'nearest_town', addresses.nearest_town,
        'building_name', addresses.building_name,
        'floor', addresses.floor,
        'door', addresses.door,
        'instructions', addresses.instructions,
        'postal_code', addresses.postal_code,
        'country_id', addresses.country_id,
        'latitude', addresses.latitude,
        'longitude', addresses.longitude
      ))
      FROM addresses
      WHERE addresses.id = delivery_requests.#{source_column}
    SQL
  end

  def restore_address_table(target_column, source_column)
    execute <<~SQL.squish
      WITH address_snapshots AS (
        SELECT
          id AS delivery_request_id,
          gen_random_uuid() AS address_id,
          #{source_column} AS snapshot,
          created_at,
          updated_at
        FROM delivery_requests
      ),
      inserted_addresses AS (
        INSERT INTO addresses (
          id, line1, line2, city, county_id, nearest_town, building_name,
          floor, door, instructions, postal_code, country_id, latitude,
          longitude, created_at, updated_at
        )
        SELECT
          address_id,
          snapshot ->> 'line1',
          snapshot ->> 'line2',
          snapshot ->> 'city',
          NULLIF(snapshot ->> 'county_id', '')::uuid,
          snapshot ->> 'nearest_town',
          snapshot ->> 'building_name',
          snapshot ->> 'floor',
          snapshot ->> 'door',
          snapshot ->> 'instructions',
          snapshot ->> 'postal_code',
          NULLIF(snapshot ->> 'country_id', '')::uuid,
          (snapshot ->> 'latitude')::decimal,
          (snapshot ->> 'longitude')::decimal,
          created_at,
          updated_at
        FROM address_snapshots
        RETURNING id
      )
      UPDATE delivery_requests
      SET #{target_column} = address_snapshots.address_id
      FROM address_snapshots
      WHERE delivery_requests.id = address_snapshots.delivery_request_id
    SQL
  end
end
