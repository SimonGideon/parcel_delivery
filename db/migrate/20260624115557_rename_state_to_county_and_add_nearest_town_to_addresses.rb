class RenameStateToCountyAndAddNearestTownToAddresses < ActiveRecord::Migration[7.1]
  def change
    # Kenya's top-level administrative unit is the county, not a US-style state.
    rename_column :addresses, :state, :county
    # Many Kenyan addresses (especially outside major cities) are described
    # relative to a known landmark town rather than a formal street address.
    add_column :addresses, :nearest_town, :string
  end
end
