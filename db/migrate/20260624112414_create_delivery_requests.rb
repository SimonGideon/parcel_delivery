class CreateDeliveryRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :driver, null: true, foreign_key: true, type: :uuid
      t.references :pickup_address, null: false, foreign_key: { to_table: :addresses }, type: :uuid
      t.references :delivery_address, null: false, foreign_key: { to_table: :addresses }, type: :uuid
      t.string :package_description, null: false
      t.decimal :package_weight, precision: 8, scale: 2, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :delivery_requests, :status
  end
end
