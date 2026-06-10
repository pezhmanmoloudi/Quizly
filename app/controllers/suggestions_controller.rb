class SuggestionsController < ApplicationController
  allow_unauthenticated_access only: [:index]

  def index
    q = params[:q].to_s.strip

    if q.length < 2 || q.length > 50
      render json: { suggestions: [] }
      return
    end

    suggestions = SuggestionQuery.call(q: q, lang: params[:lang])
    render json: { suggestions: suggestions }
  end
end
