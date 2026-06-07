module ApplicationHelper
  include Pagy::Frontend
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
