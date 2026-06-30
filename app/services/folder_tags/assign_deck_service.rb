module FolderTags
  class AssignDeckService
    Result = Data.define(:ok?, :error)

    def self.call(folder_tag:, deck:, action:)
      new(folder_tag:, deck:, action:).call
    end

    def initialize(folder_tag:, deck:, action:)
      @folder_tag = folder_tag
      @deck       = deck
      @action     = action
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
      DeckFolderTag.create!(folder_tag: @folder_tag, deck: @deck)
      Result.new(ok?: true, error: nil)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
      Result.new(ok?: false, error: e.message)
    end

    def remove_deck
      record = DeckFolderTag.find_by(folder_tag: @folder_tag, deck: @deck)
      return Result.new(ok?: false, error: :not_tagged) unless record

      record.destroy
      Result.new(ok?: true, error: nil)
    end
  end
end
