class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string

    # Backfill: derive a URL-safe username from the email prefix for every existing user.
    # Collision resolution appends _1, _2, … until unique.
    User.find_each do |user|
      base = user.email_address.split("@").first.downcase.gsub(/[^a-z0-9_]/, "_")
      candidate = base
      n = 1
      while User.exists?(username: candidate)
        candidate = "#{base}_#{n}"
        n += 1
      end
      user.update_columns(username: candidate)
    end

    change_column_null :users, :username, false
    add_index :users, :username, unique: true
  end
end
