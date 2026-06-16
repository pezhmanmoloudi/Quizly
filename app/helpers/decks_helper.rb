module DecksHelper
  # Returns one of: :not_logged_in, :owner, :already_saved, :can_save
  # locked_preview is a separate UI concern handled by @locked in the view.
  def deck_library_state(deck, user)
    return :not_logged_in unless user
    return :owner         if deck.user_id == user.id
    return :already_saved if deck.saved_by?(user)
    :can_save
  end
end
