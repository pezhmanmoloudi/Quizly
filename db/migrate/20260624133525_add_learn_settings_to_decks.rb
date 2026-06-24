class AddLearnSettingsToDecks < ActiveRecord::Migration[8.1]
  def change
    add_column :decks, :learn_new_cards_limit,    :integer, default: 10,       null: false
    add_column :decks, :learn_mastery_threshold,   :integer, default: 80,       null: false
    add_column :decks, :learn_hints_enabled,       :boolean, default: true,     null: false
    add_column :decks, :learn_weak_cards_priority, :string,  default: "normal", null: false
  end
end
