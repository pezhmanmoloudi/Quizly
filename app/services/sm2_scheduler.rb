class Sm2Scheduler
  MIN_EASE_FACTOR = 1.3

  def self.grade_card(card_progress, quality)
    quality = quality.to_i.clamp(0, 5)

    if quality >= 3
      card_progress.interval    = next_interval(card_progress)
      card_progress.repetitions += 1
      card_progress.ease_factor = [
        MIN_EASE_FACTOR,
        card_progress.ease_factor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)
      ].max.round(4)
    else
      card_progress.repetitions = 0
      card_progress.interval    = 1
    end

    card_progress.next_review_at   = card_progress.interval.days.from_now
    card_progress.last_reviewed_at = Time.current
    card_progress.save!
    card_progress
  end

  private_class_method def self.next_interval(cp)
    case cp.repetitions
    when 0 then 1
    when 1 then 6
    else        (cp.interval * cp.ease_factor).round
    end
  end
end
