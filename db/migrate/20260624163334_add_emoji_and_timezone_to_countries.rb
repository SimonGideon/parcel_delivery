class AddEmojiAndTimezoneToCountries < ActiveRecord::Migration[7.1]
  def change
    add_column :countries, :emoji, :string, limit: 191
    add_column :countries, :emoji_u, :string, limit: 191
    # Single timezone string + UTC offset in minutes -- every country we seed
    # has exactly one zone, unlike the source dataset's full per-zone array.
    add_column :countries, :timezone, :string
    add_column :countries, :gmt_offset, :integer
  end
end
