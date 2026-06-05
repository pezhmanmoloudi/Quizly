module ApplicationHelper
  include Pagy::Frontend
  def format_study_time(seconds)
    return "—" unless seconds.is_a?(Integer) && seconds > 0
    if seconds < 60
      "#{seconds}s"
    elsif seconds < 3600
      m, s = seconds.divmod(60)
      s > 0 ? "#{m}m #{s}s" : "#{m}m"
    else
      h, remainder = seconds.divmod(3600)
      m = remainder / 60
      m > 0 ? "#{h}h #{m}m" : "#{h}h"
    end
  end
end
