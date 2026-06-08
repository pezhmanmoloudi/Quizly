class CreateBadges < ActiveRecord::Migration[8.0]
  def change
    create_table :badges do |t|
      t.string :key,         null: false
      t.string :name,        null: false
      t.string :description, null: false
      t.string :icon,        null: false
      t.string :category,    null: false
      t.timestamps
    end
    add_index :badges, :key, unique: true

    create_table :user_badges do |t|
      t.references :user,  null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true
      t.datetime :earned_at, null: false
      t.timestamps
    end
    add_index :user_badges, [:user_id, :badge_id], unique: true
  end
end
