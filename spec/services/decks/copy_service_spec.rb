require "rails_helper"

RSpec.describe Decks::CopyService do
  let(:owner)  { create(:user) }
  let(:copier) { create(:user) }
  let!(:source) { create(:deck, :public, user: owner) }

  subject(:result) { described_class.call(source_deck: source, user: copier) }

  it "creates a new deck belonging to the copying user" do
    expect { result }.to change(Deck, :count).by(1)
    expect(result.user).to eq(copier)
  end

  it "sets the copied deck to private" do
    expect(result.visibility).to eq("private")
  end

  it "sets access_mode to open" do
    expect(result.access_mode).to eq("open")
  end

  it "uses the source deck name by default" do
    expect(result.name).to eq(source.name)
  end

  it "accepts a custom name override" do
    custom = described_class.call(source_deck: source, user: copier, name: "My Copy")
    expect(custom.name).to eq("My Copy")
  end

  it "does not clone the password_digest" do
    protected_source = create(:deck, :password_protected, user: owner)
    copy = described_class.call(source_deck: protected_source, user: copier)
    expect(copy.password_digest).to be_nil
  end
end
