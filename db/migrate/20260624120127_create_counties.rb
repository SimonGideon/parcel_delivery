class CreateCounties < ActiveRecord::Migration[7.1]
  def change
    create_table :counties, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.references :country, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :counties, [:country_id, :name], unique: true
  end
end
