class DropLibraryItems < ActiveRecord::Migration[8.0]
  def up
    drop_table :library_items
  end

  def down
    create_table :library_items do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :deck, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :library_items, [ :user_id, :deck_id ], unique: true
  end
end
