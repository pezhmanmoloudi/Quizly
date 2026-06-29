require "rails_helper"

# Guards against the class of bug where keys are added to en.yml but never
# propagated to the other locales (or where a mis-indented key ejects whole
# namespaces into a bogus root key). English is the source of truth; every
# other locale must define exactly the same set of keys.
RSpec.describe "Locale parity", type: :i18n do
  # Plural locales legitimately carry extra CLDR categories (e.g. ru: few/many,
  # ar: zero/two) that English (one/other) does not.
  CLDR_EXTRA = /\.(zero|two|few|many)\z/

  def flatten_keys(hash, prefix = nil)
    hash.flat_map do |key, value|
      full = [prefix, key].compact.join(".")
      value.is_a?(Hash) ? flatten_keys(value, full) : full
    end
  end

  def keys_for(locale)
    data = YAML.load_file(Rails.root.join("config", "locales", "#{locale}.yml"))
    raise "#{locale}.yml has unexpected root keys: #{data.keys}" unless data.keys == [locale.to_s]

    flatten_keys(data[locale.to_s]).to_set
  end

  let(:english_keys) { keys_for(:en) }
  let(:other_locales) { I18n.available_locales - [:en] }

  it "covers all 10 configured locales" do
    expect(I18n.available_locales).to match_array(%i[en es fr de pt ar fa ckb tr ru])
  end

  it "defines a single root key per locale file (no ejected namespaces)" do
    I18n.available_locales.each do |locale|
      data = YAML.load_file(Rails.root.join("config", "locales", "#{locale}.yml"))
      expect(data.keys).to eq([locale.to_s]), "#{locale}.yml should have exactly one root key, got #{data.keys.inspect}"
    end
  end

  it "has every English key present in every other locale" do
    other_locales.each do |locale|
      missing = english_keys - keys_for(locale)
      expect(missing).to be_empty, "#{locale} is missing keys: #{missing.to_a.sort.first(20).inspect}"
    end
  end

  it "has no keys beyond English (other than CLDR plural categories)" do
    other_locales.each do |locale|
      extra = (keys_for(locale) - english_keys).reject { |k| k.match?(CLDR_EXTRA) }
      expect(extra).to be_empty, "#{locale} has unexpected extra keys: #{extra.to_a.sort.first(20).inspect}"
    end
  end
end
