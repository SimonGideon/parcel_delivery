class CreateAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :addresses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :state
      t.string :postal_code
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false

      t.timestamps
    end
  end
end
