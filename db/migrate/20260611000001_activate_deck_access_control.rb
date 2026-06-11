class ActivateDeckAccessControl < ActiveRecord::Migration[8.0]
  def up
    Deck.where(visibility: "public").update_all(visibility: "everyone")
  end

  def down
    Deck.where(visibility: "everyone").update_all(visibility: "public")
  end
end
