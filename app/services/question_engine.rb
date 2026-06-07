class QuestionEngine
  TYPES = %w[multiple_choice written true_false matching].freeze
  MC_MIN_POOL = 4

  def self.generate(flashcards:, types: TYPES, count: nil)
    new(flashcards: flashcards.to_a, types: Array(types).map(&:to_s)).generate(count: count)
  end

  def self.check_answer(question, user_answer)
    correct = question["correct_answer"].to_s
    case question["type"]
    when "written"
      normalize(user_answer) == normalize(correct)
    when "matching"
      begin
        user_pairs    = JSON.parse(user_answer.to_s).transform_values { |v| v.to_s.strip }
        correct_pairs = JSON.parse(correct).transform_values { |v| v.to_s.strip }
        user_pairs == correct_pairs
      rescue JSON::ParserError
        false
      end
    else
      user_answer.to_s.strip == correct.strip
    end
  end

  def initialize(flashcards:, types:)
    @flashcards = flashcards
    @types      = types & TYPES
    @types      = TYPES if @types.empty?
  end

  def generate(count: nil)
    pool = @flashcards.shuffle
    pool = pool.first(count) if count
    pool.map { |card| build_question(card) }
  end

  private

  def build_question(flashcard)
    available = usable_types_for(flashcard)
    type = available.sample
    send(:"build_#{type}", flashcard)
  end

  def usable_types_for(flashcard)
    types = @types.dup
    types.delete("multiple_choice") if @flashcards.size < MC_MIN_POOL
    types.delete("matching")        if @flashcards.size < MC_MIN_POOL
    types.delete("true_false")      if @flashcards.size < 2
    types.any? ? types : [ "written" ]
  end

  def build_multiple_choice(flashcard)
    distractors = (@flashcards - [ flashcard ]).sample(3).map(&:back_content)
    options = ([ flashcard.back_content ] + distractors).shuffle
    {
      "flashcard_id"   => flashcard.id,
      "type"           => "multiple_choice",
      "prompt"         => flashcard.front_content,
      "correct_answer" => flashcard.back_content,
      "options"        => options
    }
  end

  def build_written(flashcard)
    {
      "flashcard_id"   => flashcard.id,
      "type"           => "written",
      "prompt"         => flashcard.front_content,
      "correct_answer" => flashcard.back_content,
      "options"        => []
    }
  end

  def build_matching(flashcard)
    others = (@flashcards - [ flashcard ]).sample(3)
    pool   = ([ flashcard ] + others).first(4)
    pairs  = pool.map { |c| { "id" => c.id.to_s, "term" => c.front_content, "definition" => c.back_content } }
    correct = pairs.each_with_object({}) { |p, h| h[p["id"]] = p["definition"] }
    {
      "flashcard_id"   => flashcard.id,
      "type"           => "matching",
      "prompt"         => I18n.t("question_engine.match_prompt"),
      "correct_answer" => correct.to_json,
      "options"        => {
        "terms"       => pairs.map { |p| { "id" => p["id"], "text" => p["term"] } },
        "definitions" => pairs.map { |p| { "id" => p["id"], "text" => p["definition"] } }.shuffle
      }
    }
  end

  def build_true_false(flashcard)
    is_correct = [ true, false ].sample
    if is_correct
      statement = "#{flashcard.front_content} → #{flashcard.back_content}"
      answer = "true"
    else
      impostor = (@flashcards - [ flashcard ]).sample
      wrong_back = impostor&.back_content || I18n.t("shared.not_available")
      statement = "#{flashcard.front_content} → #{wrong_back}"
      answer = "false"
    end
    {
      "flashcard_id"   => flashcard.id,
      "type"           => "true_false",
      "prompt"         => statement,
      "correct_answer" => answer,
      "options"        => [ "true", "false" ]
    }
  end

  def self.normalize(str)
    str.to_s.strip.downcase.gsub(/\s+/, " ")
  end
  private_class_method :normalize
end
