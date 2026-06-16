module Folders
  class AssignDeckService
    Result = Data.define(:ok?, :error)

    def self.call(folder:, deck:, action:)
      new(folder:, deck:, action:).call
    end

    def initialize(folder:, deck:, action:)
      @folder = folder
      @deck   = deck
      @action = action
    end

    def call
      case @action
      when :add    then add_deck
      when :remove then remove_deck
      else Result.new(ok?: false, error: :unknown_action)
      end
    end

    private

    def add_deck
      DeckFolder.create!(deck: @deck, folder: @folder)
      Result.new(ok?: true, error: nil)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
      Result.new(ok?: false, error: e.message)
    end

    def remove_deck
      record = DeckFolder.find_by(deck: @deck, folder: @folder)
      return Result.new(ok?: false, error: :not_in_folder) unless record

      record.destroy
      Result.new(ok?: true, error: nil)
    end
  end
end
