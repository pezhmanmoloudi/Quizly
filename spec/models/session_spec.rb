require "rails_helper"

RSpec.describe Session, type: :model do
  describe "associations" do
    it "belongs to a user" do
      assoc = described_class.reflect_on_association(:user)
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "database columns" do
    it "stores ip_address" do
      expect(described_class.column_names).to include("ip_address")
    end

    it "stores user_agent" do
      expect(described_class.column_names).to include("user_agent")
    end
  end

  describe "behavior" do
    it "is valid when associated with a user" do
      user    = create(:user)
      session = Session.create!(user: user)
      expect(session).to be_persisted
    end

    it "is destroyed when its user is destroyed" do
      user    = create(:user)
      Session.create!(user: user)
      expect { user.destroy }.to change(Session, :count).by(-1)
    end
  end
end
