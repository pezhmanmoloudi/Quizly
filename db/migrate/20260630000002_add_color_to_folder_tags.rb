class AddColorToFolderTags < ActiveRecord::Migration[8.1]
  def change
    add_column :folder_tags, :color, :string
  end
end
