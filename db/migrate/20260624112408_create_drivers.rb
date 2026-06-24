class CreateDrivers < ActiveRecord::Migration[7.1]
  def change
    create_table :drivers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :phone
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :drivers, :email, unique: true
    add_index :drivers, :status
  end
end
