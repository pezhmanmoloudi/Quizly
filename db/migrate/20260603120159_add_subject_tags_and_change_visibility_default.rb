class AddSubjectTagsAndChangeVisibilityDefault < ActiveRecord::Migration[8.1]
  def change
    add_column :decks, :subject_tags, :string
    change_column_default :decks, :visibility, from: "private", to: "public"
  end
end
