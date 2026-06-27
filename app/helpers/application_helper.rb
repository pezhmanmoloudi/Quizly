module ApplicationHelper
  include Pagy::Method

  def text_direction_for(lang_code)
    ScriptDetector.for_lang(lang_code) == :rtl ? "rtl" : "ltr"
  end

  def pagy_series(pagy)
    pagy.send(:series)
  end

  def highlight_match(word, query)
    return h(word) if query.blank?
    idx = word.downcase.index(query.downcase)
    return h(word) unless idx
    safe_join([
      h(word[0...idx]),
      content_tag(:mark, word[idx, query.length]),
      h(word[(idx + query.length)..])
    ])
  end

  def google_oauth_available?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  def github_oauth_available?
    ENV["GITHUB_CLIENT_ID"].present? && ENV["GITHUB_CLIENT_SECRET"].present?
  end

  def oauth_available?
    google_oauth_available? || github_oauth_available?
  end

  def format_study_time(seconds)
    return I18n.t("time.none") unless seconds.is_a?(Integer) && seconds > 0
    if seconds < 60
      I18n.t("time.seconds", n: seconds)
    elsif seconds < 3600
      m, s = seconds.divmod(60)
      s > 0 ? I18n.t("time.minutes_seconds", m: m, s: s) : I18n.t("time.minutes", m: m)
    else
      h, remainder = seconds.divmod(3600)
      m = remainder / 60
      m > 0 ? I18n.t("time.hours_minutes", h: h, m: m) : I18n.t("time.hours", h: h)
    end
  end
end
