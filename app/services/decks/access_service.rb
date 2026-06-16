module Decks
  class AccessService
    # Immutable access state consumed by controllers and views.
    # state: :allowed | :locked | :denied
    AccessResult = Data.define(:state, :owner, :password_protected) do
      def allowed?           = state == :allowed
      def locked?            = state == :locked
      def denied?            = state == :denied
      def owner?             = owner
      def requires_password? = password_protected
    end

    UnlockResult = Data.define(:ok?, :error)

    # Evaluate current access state for a deck/user/session combination.
    # Call AFTER authorize @deck, :show? so Pundit handles the :denied case first.
    def self.evaluate(deck:, user:, session:)
      new(deck:, user:, session:).evaluate
    end

    # Validate a password submission and set the session unlock flag on success.
    def self.call(deck:, password:, session:)
      new(deck:, password:, session:).perform_unlock
    end

    # Read-only session flag check (kept for backward compatibility).
    def self.unlocked?(deck:, session:)
      session["deck_#{deck.id}_unlocked"] == true
    end

    def initialize(deck:, user: nil, password: nil, session: {})
      @deck     = deck
      @user     = user
      @password = password
      @session  = session
    end

    def evaluate
      return AccessResult.new(state: :denied, owner: false, password_protected: false) if denied?
      return AccessResult.new(state: :locked, owner: owner?, password_protected: true) if locked?
      AccessResult.new(state: :allowed, owner: owner?, password_protected: @deck.password_protected?)
    end

    def perform_unlock
      if @deck.authenticate_password(@password.to_s)
        @session["deck_#{@deck.id}_unlocked"] = true
        UnlockResult.new(ok?: true, error: nil)
      else
        UnlockResult.new(ok?: false, error: :invalid_password)
      end
    end

    private

    def denied?         = @deck.private? && !owner?
    def locked?         = @deck.password_protected? && !session_unlocked? && !owner?
    def owner?          = @user.present? && @deck.user_id == @user.id
    def session_unlocked? = @session["deck_#{@deck.id}_unlocked"] == true
  end
end
