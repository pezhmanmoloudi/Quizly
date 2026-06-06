class QuestionEngine
  TYPES = %w[multiple_choice written true_false].freeze
  MC_MIN_POOL = 4

  def self.generate(flashcards:, types: TYPES, count: nil)
    new(flashcards: flashcards.to_a, types: Array(types).map(&:to_s)).generate(count: count)
  end

  def self.check_answer(question, user_answer)
    correct = question["correct_answer"].to_s
    case question["type"]
    when "written"
      normalize(user_answer) == normalize(correct)
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

  def build_true_false(flashcard)
    is_correct = [ true, false ].sample
    if is_correct
      statement = "#{flashcard.front_content} → #{flashcard.back_content}"
      answer = "true"
    else
      impostor = (@flashcards - [ flashcard ]).sample
      wrong_back = impostor&.back_content || "N/A"
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
