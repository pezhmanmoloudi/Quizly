require "rails_helper"

RSpec.describe LocalizationHelper, type: :helper do
  describe "#localize_digits" do
    it "transliterates ASCII digits to Persian digits under :fa" do
      I18n.with_locale(:fa) { expect(helper.localize_digits("59")).to eq("۵۹") }
    end

    it "transliterates ASCII digits to Arabic-Indic digits under :ar and :ckb" do
      I18n.with_locale(:ar) { expect(helper.localize_digits("10")).to eq("١٠") }
      I18n.with_locale(:ckb) { expect(helper.localize_digits("10")).to eq("١٠") }
    end

    it "leaves digits untouched for Latin-script locales" do
      I18n.with_locale(:en) { expect(helper.localize_digits("1,234")).to eq("1,234") }
      I18n.with_locale(:de) { expect(helper.localize_digits("1.234")).to eq("1.234") }
    end
  end

  describe "#localized_number" do
    it "applies the locale grouping separator and native digits" do
      I18n.with_locale(:de) { expect(helper.localized_number(1234)).to eq("1.234") }
      I18n.with_locale(:fa) { expect(helper.localized_number(1234)).to eq("۱٬۲۳۴") }
      I18n.with_locale(:en) { expect(helper.localized_number(1234)).to eq("1,234") }
    end
  end

  describe "#localized_time_ago" do
    it "translates the relative time and localizes its digits" do
      time = 10.hours.ago
      I18n.with_locale(:de) { expect(helper.localized_time_ago(time)).to eq("etwa 10 Stunden") }
      I18n.with_locale(:fa) { expect(helper.localized_time_ago(time)).to eq("حدود ۱۰ ساعت") }
    end
  end
end
