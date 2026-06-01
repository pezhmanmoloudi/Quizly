class CreateFlashcards < ActiveRecord::Migration[8.0]
  def change
    create_table :flashcards do |t|
      t.references :deck, null: false, foreign_key: true
      t.text :front_content, null: false
      t.text :back_content,  null: false
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
