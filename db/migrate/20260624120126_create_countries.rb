class CreateCountries < ActiveRecord::Migration[7.1]
  def change
    create_table :countries, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :code

      t.timestamps
    end
    add_index :countries, :name, unique: true
  end
end
