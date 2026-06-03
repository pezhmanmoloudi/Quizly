require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#format_study_time" do
    it "returns '—' for nil" do
      expect(helper.format_study_time(nil)).to eq("—")
    end

    it "returns '—' for zero" do
      expect(helper.format_study_time(0)).to eq("—")
    end

    it "formats seconds only" do
      expect(helper.format_study_time(45)).to eq("45s")
    end

    it "formats minutes and seconds" do
      expect(helper.format_study_time(125)).to eq("2m 5s")
    end

    it "formats exact minutes without seconds" do
      expect(helper.format_study_time(120)).to eq("2m")
    end

    it "formats hours and minutes" do
      expect(helper.format_study_time(3720)).to eq("1h 2m")
    end

    it "formats exact hours without minutes" do
      expect(helper.format_study_time(3600)).to eq("1h")
    end
  end
end
