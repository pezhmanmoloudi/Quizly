class AddShareTokenToDecks < ActiveRecord::Migration[8.1]
  def up
    add_column :decks, :share_token, :string
    add_index  :decks, :share_token, unique: true

    Deck.find_each do |deck|
      deck.update_columns(share_token: SecureRandom.urlsafe_base64(32))
    end
  end

  def down
    remove_index  :decks, :share_token
    remove_column :decks, :share_token
  end
end
