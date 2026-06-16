class RefactorDeckAccessAndAddFolders < ActiveRecord::Migration[8.1]
  def up
    # ── Decks: add access_mode, backfill, then drop edit_permission ───────────

    add_column :decks, :access_mode, :string

    execute <<~SQL
      UPDATE decks
      SET access_mode = CASE
        WHEN edit_permission = 'people_with_password' AND password_digest IS NOT NULL THEN 'password'
        ELSE 'open'
      END
    SQL

    change_column_null    :decks, :access_mode, false, "open"
    change_column_default :decks, :access_mode, "open"
    add_index :decks, :access_mode

    remove_index  :decks, name: "index_decks_on_edit_permission", if_exists: true
    remove_column :decks, :edit_permission

    # ── Folders ───────────────────────────────────────────────────────────────

    create_table :folders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    # ── DeckFolders join table ─────────────────────────────────────────────────

    create_table :deck_folders do |t|
      t.references :deck,   null: false, foreign_key: { on_delete: :cascade }
      t.references :folder, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    add_index :deck_folders, [ :deck_id, :folder_id ], unique: true
  end

  def down
    drop_table :deck_folders
    drop_table :folders

    remove_index  :decks, :access_mode, if_exists: true
    remove_column :decks, :access_mode

    add_column :decks, :edit_permission, :string

    execute <<~SQL
      UPDATE decks
      SET edit_permission = CASE
        WHEN access_mode = 'password' THEN 'people_with_password'
        ELSE 'only_me'
      END
    SQL

    change_column_null    :decks, :edit_permission, false, "only_me"
    change_column_default :decks, :edit_permission, "only_me"
    add_index :decks, :edit_permission
  end
end
