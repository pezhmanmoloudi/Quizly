module LocalizationHelper
  # Eastern-Arabic numeral sets for locales that use a non-Latin digit script.
  EASTERN_DIGITS = {
    "fa"  => %w[۰ ۱ ۲ ۳ ۴ ۵ ۶ ۷ ۸ ۹],
    "ar"  => %w[٠ ١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩],
    "ckb" => %w[٠ ١ ٢ ٣ ٤ ٥ ٦ ٧ ٨ ٩]
  }.freeze

  # Transliterate ASCII digits in any string to the current locale's native digits.
  def localize_digits(value)
    string = value.to_s
    digits = EASTERN_DIGITS[I18n.locale.to_s]
    return string unless digits

    string.gsub(/[0-9]/) { |d| digits[d.to_i] }
  end

  # Locale-aware integer/number (grouping separator from rails-i18n) in native digits.
  def localized_number(number)
    localize_digits(number_with_delimiter(number))
  end

  # Locale-aware relative time ("about 10 hours" translated by rails-i18n) in native digits.
  def localized_time_ago(time)
    localize_digits(time_ago_in_words(time))
  end
end
