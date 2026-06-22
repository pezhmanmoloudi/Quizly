require "rails_helper"

RSpec.describe Follow, type: :model do
  describe "associations" do
    it "belongs to follower (User)" do
      assoc = described_class.reflect_on_association(:follower)
      expect(assoc.macro).to eq(:belongs_to)
      expect(assoc.options[:class_name]).to eq("User")
    end

    it "belongs to followed (User) with counter_cache on followers_count" do
      assoc = described_class.reflect_on_association(:followed)
      expect(assoc.macro).to eq(:belongs_to)
      expect(assoc.options[:class_name]).to eq("User")
      # Rails 7+ stores counter_cache as a hash: { active: true, column: "..." }
      counter = assoc.options[:counter_cache]
      expect(counter).to be_present
      column = counter.is_a?(Hash) ? counter[:column] : counter.to_s
      expect(column).to eq("followers_count")
    end
  end

  describe "validations" do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    it "is valid with distinct follower and followed" do
      follow = build(:follow, follower: follower, followed: followed)
      expect(follow).to be_valid
    end

    it "is invalid when follower and followed are the same user" do
      follow = build(:follow, follower: follower, followed: follower)
      expect(follow).not_to be_valid
      expect(follow.errors[:base]).not_to be_empty
    end

    it "is invalid when the same follower already follows the same followed user" do
      create(:follow, follower: follower, followed: followed)
      duplicate = build(:follow, follower: follower, followed: followed)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:follower_id]).not_to be_empty
    end
  end

  describe "counter cache" do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    it "increments followed.followers_count on create" do
      expect { create(:follow, follower: follower, followed: followed) }
        .to change { followed.reload.followers_count }.by(1)
    end

    it "decrements followed.followers_count on destroy" do
      follow = create(:follow, follower: follower, followed: followed)
      expect { follow.destroy }
        .to change { followed.reload.followers_count }.by(-1)
    end

    it "does not change follower.followers_count" do
      expect { create(:follow, follower: follower, followed: followed) }
        .not_to change { follower.reload.followers_count }
    end
  end

  describe "cascade destroy" do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    it "is destroyed when the follower user is destroyed" do
      follow = create(:follow, follower: follower, followed: followed)
      follower.destroy
      expect(Follow.find_by(id: follow.id)).to be_nil
    end

    it "is destroyed when the followed user is destroyed" do
      follow = create(:follow, follower: follower, followed: followed)
      followed.destroy
      expect(Follow.find_by(id: follow.id)).to be_nil
    end
  end
end
