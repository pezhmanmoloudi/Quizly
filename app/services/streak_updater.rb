class StreakUpdater
  def self.call(user)
    user.with_lock do
      today = Date.current
      return if user.last_studied_on == today

      new_streak = user.last_studied_on == today - 1 ? user.current_streak + 1 : 1
      longest    = [user.longest_streak, new_streak].max

      user.update_columns(
        current_streak:  new_streak,
        longest_streak:  longest,
        last_studied_on: today
      )
    end
  end
end
