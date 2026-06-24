class CreateDeliveryEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :delivery_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :delivery_request, null: false, foreign_key: true, type: :uuid
      t.integer :event_type, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end
    add_index :delivery_events, :event_type
  end
end
