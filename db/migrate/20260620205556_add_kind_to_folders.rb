class AddKindToFolders < ActiveRecord::Migration[8.1]
  def change
    add_column :folders, :kind, :string, null: false, default: "manual"
    add_index  :folders, :kind
  end
end
