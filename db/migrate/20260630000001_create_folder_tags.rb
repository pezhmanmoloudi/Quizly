class CreateFolderTags < ActiveRecord::Migration[8.1]
  def change
    create_table :folder_tags do |t|
      t.references :folder, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.timestamps
    end

    add_index :folder_tags, [ :folder_id, :name ], unique: true

    create_table :deck_folder_tags do |t|
      t.references :folder_tag, null: false, foreign_key: { on_delete: :cascade }
      t.references :deck,       null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    add_index :deck_folder_tags, [ :folder_tag_id, :deck_id ], unique: true
  end
end
