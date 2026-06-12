class RemoveOrphanedDeckColumns < ActiveRecord::Migration[8.1]
  def up
    remove_index  :decks, name: "index_decks_on_status", if_exists: true
    remove_column :decks, :status
    remove_column :decks, :definition_language_code
  end

  def down
    add_column :decks, :status, :string, default: "draft", null: false
    add_column :decks, :definition_language_code, :string
    add_index  :decks, :status, name: "index_decks_on_status"
  end
end
