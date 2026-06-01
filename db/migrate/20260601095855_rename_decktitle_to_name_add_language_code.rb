class RenameDecktitleToNameAddLanguageCode < ActiveRecord::Migration[8.1]
  def change
    rename_column :decks, :title, :name
    add_column :decks, :language_code, :string
  end
end
