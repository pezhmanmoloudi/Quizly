module Folders
  # Suggested tag names shown as quick-add chips in the tag modals.
  # The base list is localized; names already used in the folder are removed.
  class RecommendedTags
    def self.for(folder)
      new(folder).call
    end

    def initialize(folder)
      @folder = folder
    end

    def call
      existing = @folder.folder_tags.pluck(:name).map { |n| n.downcase.strip }.to_set
      base_list.reject { |name| existing.include?(name.downcase.strip) }
    end

    private

    def base_list
      Array(I18n.t("folders.tags_modal.recommended", default: []))
    end
  end
end
