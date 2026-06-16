class DeckAccessController < ApplicationController
  include DeckScoped

  allow_unauthenticated_access only: [ :show, :create ]

  before_action :set_deck

  def show
    @access = Decks::AccessService.evaluate(deck: @deck, user: Current.user, session: session)
    raise Pundit::NotAuthorizedError if @access.denied?
    redirect_to @deck if @access.allowed?
    # :locked → fall through and render the unlock form
  end

  def create
    @access = Decks::AccessService.evaluate(deck: @deck, user: Current.user, session: session)
    raise Pundit::NotAuthorizedError if @access.denied?

    result = Decks::AccessService.call(
      deck:     @deck,
      password: params[:password].to_s,
      session:  session
    )

    if result.ok?
      redirect_to @deck, notice: t("decks.unlock.success")
    else
      flash.now[:alert] = t("decks.unlock.invalid_password")
      render :show, status: :unprocessable_entity
    end
  end
end
