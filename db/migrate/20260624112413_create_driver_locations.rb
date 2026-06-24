class CreateDriverLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :driver_locations do |t|
      t.references :driver, null: false, foreign_key: true
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.datetime :recorded_at, null: false

      t.timestamps
    end
    add_index :driver_locations, [:driver_id, :recorded_at]
  end
end
