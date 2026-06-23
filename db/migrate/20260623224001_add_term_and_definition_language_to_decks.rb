class AddTermAndDefinitionLanguageToDecks < ActiveRecord::Migration[8.0]
  def up
    add_column :decks, :term_language,       :string
    add_column :decks, :definition_language, :string
    execute <<~SQL
      UPDATE decks
      SET    term_language = language_code,
             definition_language = language_code
      WHERE  language_code IS NOT NULL
    SQL
  end

  def down
    remove_column :decks, :term_language
    remove_column :decks, :definition_language
  end
end
