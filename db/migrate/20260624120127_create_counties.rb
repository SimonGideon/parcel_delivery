class CreateCounties < ActiveRecord::Migration[7.1]
  def change
    create_table :counties do |t|
      t.string :name, null: false
      t.references :country, null: false, foreign_key: true

      t.timestamps
    end
    add_index :counties, [:country_id, :name], unique: true
  end
end
