# frozen_string_literal: true

class DeckPolicy < ApplicationPolicy
  # ── Read ────────────────────────────────────────────────────────────────────

  # Covers show, study, learn, test, flashcard, match
  def show?
    record.can_view?(user)
  end

  # ── Owner-only settings ──────────────────────────────────────────────────────

  def edit?    = owner?
  def update?  = owner?
  def destroy? = owner?

  def update_visibility? = owner?

  # ── Content editing (flashcards + imports) ───────────────────────────────────
  # Owner always yes; non-owner with an unlocked password-protected deck also yes.
  # `record.unlocked` is stamped from the session by the controller before authorize is called.

  def edit_content?
    record.can_edit?(user)
  end

  # ── Library / copy actions ───────────────────────────────────────────────────

  def fork?
    record.can_save?(user)
  end

  def copy?
    record.can_copy?(user)
  end

  private

  def owner?
    user.present? && user.id == record.user_id
  end
end
