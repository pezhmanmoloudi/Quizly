class ScriptDetector
  LANG_SCRIPT_MAP = {
    rtl:        %w[ar fa ckb ur ps sd he yi],
    cyrillic:   %w[ru uk bg sr mk be tt],
    cjk:        %w[zh ja ko],
    devanagari: %w[hi mr ne],
    greek:      %w[el],
    thai:       %w[th],
    georgian:   %w[ka],
    armenian:   %w[hy]
  }.freeze

  # Returns the predominant Unicode script of +str+ as a Symbol.
  def self.call(str)
    new(str).call
  end

  # Maps an ISO 639-1 language code to its expected script Symbol.
  # Unknown codes → :latin.
  def self.for_lang(lang)
    code = lang.to_s.strip
    LANG_SCRIPT_MAP.each { |script, codes| return script if codes.include?(code) }
    :latin
  end

  def initialize(str)
    @str = str.to_s
  end

  def call
    sample = @str.scan(/\p{L}/).first(20).join
    return :latin if sample.empty?
    return :rtl        if sample.match?(/[\p{Arabic}\p{Hebrew}]/)
    return :cyrillic   if sample.match?(/\p{Cyrillic}/)
    return :cjk        if sample.match?(/[\p{Han}\p{Hiragana}\p{Katakana}]/)
    return :devanagari if sample.match?(/\p{Devanagari}/)
    return :greek      if sample.match?(/\p{Greek}/)
    return :thai       if sample.match?(/\p{Thai}/)
    :latin
  end
end
