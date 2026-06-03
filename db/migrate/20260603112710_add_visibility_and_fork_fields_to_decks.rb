class AddVisibilityAndForkFieldsToDecks < ActiveRecord::Migration[8.1]
  def change
    add_column :decks, :visibility, :string, null: false, default: "private"
    add_column :decks, :forked_from_id, :integer
    add_column :decks, :forks_count, :integer, null: false, default: 0

    add_index :decks, :visibility
    add_index :decks, :forked_from_id
    add_foreign_key :decks, :decks, column: :forked_from_id
  end
end
