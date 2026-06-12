class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.bigint  :recipient_id, null: false
      t.bigint  :actor_id
      t.string  :event_type,       null: false
      t.string  :notifiable_type
      t.bigint  :notifiable_id
      t.boolean :read,             default: false, null: false
      t.datetime :read_at
      t.timestamps

      t.index [ :recipient_id, :read, :created_at ]
      t.index [ :recipient_id, :created_at ]
      t.index [ :notifiable_type, :notifiable_id ]
    end

    add_foreign_key :notifications, :users, column: :recipient_id
    add_foreign_key :notifications, :users, column: :actor_id
  end
end
