class AddTimezoneToCountries < ActiveRecord::Migration[7.1]
  def change
    # Single timezone string + UTC offset in minutes -- every country we seed
    # has exactly one zone, unlike the source dataset's full per-zone array.
    add_column :countries, :timezone, :string
    add_column :countries, :gmt_offset, :integer
  end
end
