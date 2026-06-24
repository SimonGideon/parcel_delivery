class UpdateAddressesForCountryCountyAndReceivingDetails < ActiveRecord::Migration[7.1]
  def change
    # Replace free-text country/county with normalized references so clients
    # pick from a real list instead of typing strings prone to typos.
    remove_column :addresses, :country, :string
    remove_column :addresses, :county, :string

    add_reference :addresses, :country, foreign_key: true
    add_reference :addresses, :county, foreign_key: true

    # Optional details for whoever is physically receiving the delivery.
    add_column :addresses, :building_name, :string
    add_column :addresses, :floor, :string
    add_column :addresses, :door, :string
    add_column :addresses, :instructions, :text
  end
end
