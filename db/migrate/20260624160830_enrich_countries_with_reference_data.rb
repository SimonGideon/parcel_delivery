class EnrichCountriesWithReferenceData < ActiveRecord::Migration[7.1]
  def change
    # `code` was already the ISO alpha-2 code in practice; rename it to make
    # room for iso3 alongside it, matching the dr5hn countries-states-cities
    # reference dataset's naming (minus the columns we don't need yet).
    rename_column :countries, :code, :iso2
    add_column :countries, :iso3, :string, limit: 3
    add_column :countries, :phonecode, :string
    add_column :countries, :capital, :string
    add_column :countries, :currency, :string
    add_column :countries, :currency_symbol, :string
    add_column :countries, :region, :string
    add_column :countries, :latitude, :decimal, precision: 10, scale: 6
    add_column :countries, :longitude, :decimal, precision: 10, scale: 6
  end
end
