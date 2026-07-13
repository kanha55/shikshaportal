# frozen_string_literal: true

require "net/http"
require "json"

class AiQuestionPaperGeneratorService
  class GenerationError < StandardError
    attr_reader :code

    def initialize(code, **options)
      @code = code
      super(I18n.t("services.question_paper.#{code}", **options))
    end
  end

  ANTHROPIC_MODEL = "claude-haiku-4-5"
  HOURLY_CAP = 10
  MAX_TOTAL_QUESTIONS = 100
  SYSTEM_PROMPT = <<~PROMPT.squish
    You are an expert Indian school and coaching center exam paper creator.
    You create well-structured, curriculum-aligned question papers.
    Always respond in valid JSON only — no markdown, no explanation, just the JSON object.
  PROMPT

  def initialize(
    coaching_center:,
    subject:,
    class_name:,
    topic:,
    question_counts:,
    difficulty:,
    total_marks:,
    language:,
    instructions: nil
  )
    @coaching_center = coaching_center
    @subject = subject.to_s.strip
    @class_name = class_name.to_s.strip
    @topic = topic.to_s.strip
    @question_counts = normalize_counts(question_counts)
    @difficulty = difficulty.to_s
    @total_marks = total_marks.to_i
    @language = language.to_s
    @instructions = instructions.to_s.strip.presence
  end

  def call
    validate!
    normalize_payload(generate_with_fallback)
  end

  def self.hourly_usage_for(coaching_center)
    QuestionPaperGenerationLog
      .where(school: coaching_center)
      .where("created_at >= ?", 1.hour.ago)
      .count
  end

  def self.hourly_cap_reached?(coaching_center)
    hourly_usage_for(coaching_center) >= HOURLY_CAP
  end

  private

  attr_reader :coaching_center, :subject, :class_name, :topic, :question_counts,
              :difficulty, :total_marks, :language, :instructions

  def validate!
    raise GenerationError, :subject_required if subject.blank?
    raise GenerationError, :class_name_required if class_name.blank?
    raise GenerationError, :topic_required if topic.blank?
    raise GenerationError, :invalid_difficulty unless QuestionPaper::DIFFICULTIES.include?(difficulty)
    raise GenerationError, :invalid_language unless QuestionPaper::LANGUAGES.include?(language)
    raise GenerationError, :invalid_total_marks if total_marks <= 0 || total_marks > 500
    raise GenerationError, :no_question_types if question_counts.empty?
    raise GenerationError, :too_many_questions, count: total_questions if total_questions > MAX_TOTAL_QUESTIONS
    raise GenerationError, :hourly_limit if self.class.hourly_cap_reached?(coaching_center)
  end

  def total_questions
    question_counts.values.sum
  end

  def normalize_counts(raw_counts)
    counts = raw_counts.to_h.transform_keys(&:to_s).transform_values { |value| value.to_i }
    counts.select do |type, count|
      QuestionPaper::QUESTION_TYPES.include?(type) && count.positive?
    end
  end

  def generate_with_fallback
    if anthropic_api?
      payload = try_provider(:anthropic) { call_anthropic_api }
      return payload if payload
    end

    mock_response
  end

  def anthropic_api?
    ENV["ANTHROPIC_API_KEY"].present?
  end

  def try_provider(name)
    yield
  rescue GenerationError => e
    Rails.logger.warn("[AiQuestionPaperGenerator] #{name} failed (#{e.code}): #{e.message}")
    nil
  end

  def call_anthropic_api
    uri = URI("https://api.anthropic.com/v1/messages")
    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = ENV.fetch("ANTHROPIC_API_KEY")
    request["anthropic-version"] = "2023-06-01"
    request["content-type"] = "application/json"
    request.body = {
      model: ANTHROPIC_MODEL,
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: [
        { role: "user", content: user_prompt }
      ]
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 60) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise GenerationError, :service_unavailable
    end

    body = JSON.parse(response.body)
    text = body.dig("content", 0, "text")
    raise GenerationError, :empty_response if text.blank?

    parse_json_payload(text)
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError
    raise GenerationError, :service_unavailable
  end

  def user_prompt
    counts_text = question_counts.map { |type, count| "#{type}: #{count}" }.join(", ")
    instruction_line = instructions.present? ? "Additional instructions: #{instructions}" : ""

    <<~PROMPT
      Create a question paper for #{coaching_center.name}, an Indian coaching center.

      Subject: #{subject}
      Class/Grade: #{class_name}
      Topic/Chapter: #{topic}
      Question counts by type: #{counts_text}
      Difficulty: #{difficulty}
      Total marks: #{total_marks}
      Language: #{language}
      #{instruction_line}

      Return ONLY valid JSON with exactly this schema:
      {
        "paper_title": "string",
        "subject": "string",
        "class_name": "string",
        "topic": "string",
        "total_marks": number,
        "language": "string",
        "questions": [
          {
            "id": "q1",
            "type": "mcq | short_answer | long_answer | true_false | fill_blank",
            "question": "string",
            "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
            "correct_answer": "string",
            "model_answer": "string",
            "marks": number,
            "difficulty": "easy | medium | hard"
          }
        ]
      }

      Rules:
      - Include exactly the requested number of questions per type.
      - MCQ must have exactly 4 options labeled A/B/C/D and one correct_answer.
      - Short/long answer must include model_answer with key points.
      - True/false correct_answer must be "True" or "False".
      - Fill in the blanks must include correct_answer.
      - Distribute marks so question marks sum to total_marks.
      - Use ids q1, q2, q3... in order.
      - For language "both", write questions in Hindi and English where appropriate.
      - For language "hi", use Devanagari script.
      - For language "en", use English.
    PROMPT
  end

  def parse_json_payload(text)
    cleaned = text.strip
    cleaned = cleaned.gsub(/\A```json\s*|\A```\s*|\s*```\z/, "")
    JSON.parse(cleaned)
  end

  def mock_response
    questions = []
    index = 1

    question_counts.each do |type, count|
      count.times do
        questions << mock_question(type, index)
        index += 1
      end
    end

    marks_per_question = (total_marks.to_f / questions.size).ceil

    {
      "paper_title" => QuestionPaper.auto_title(subject: subject, class_name: class_name, topic: topic),
      "subject" => subject,
      "class_name" => class_name,
      "topic" => topic,
      "total_marks" => total_marks,
      "language" => language,
      "questions" => questions.map do |question|
        question.merge("marks" => marks_per_question, "difficulty" => mock_difficulty)
      end
    }
  end

  def mock_question(type, index)
    base = {
      "id" => "q#{index}",
      "type" => type,
      "question" => "#{subject} — #{topic} (#{type.tr('_', ' ')}) question #{index}",
      "correct_answer" => "Sample answer",
      "model_answer" => "Key points for #{topic} question #{index}.",
      "difficulty" => mock_difficulty
    }

    case type
    when "mcq"
      base.merge(
        "options" => [
          "A. Option one",
          "B. Option two",
          "C. Option three",
          "D. Option four"
        ],
        "correct_answer" => "B"
      )
    when "true_false"
      base.merge("correct_answer" => "True", "model_answer" => "")
    when "fill_blank"
      base.merge("correct_answer" => "sample", "model_answer" => "")
    else
      base
    end
  end

  def mock_difficulty
    return %w[easy medium hard].sample if difficulty == "mixed"

    difficulty
  end

  def normalize_payload(payload)
    title = payload["paper_title"].to_s.strip
    questions = Array(payload["questions"])
    raise GenerationError, :incomplete_response if title.blank? || questions.empty?

    normalized_questions = questions.map.with_index(1) do |question, index|
      normalize_question(question, index)
    end

    {
      paper_title: title,
      subject: payload["subject"].presence || subject,
      class_name: payload["class_name"].presence || class_name,
      topic: payload["topic"].presence || topic,
      total_marks: payload["total_marks"].presence || total_marks,
      language: payload["language"].presence || language,
      difficulty: difficulty,
      questions: normalized_questions
    }
  end

  def normalize_question(question, fallback_index)
    type = question["type"].to_s
    raise GenerationError, :invalid_question_type unless QuestionPaper::QUESTION_TYPES.include?(type)

    normalized = {
      "id" => question["id"].presence || "q#{fallback_index}",
      "type" => type,
      "question" => question["question"].to_s.strip,
      "correct_answer" => question["correct_answer"].to_s.strip,
      "model_answer" => question["model_answer"].to_s.strip,
      "marks" => question["marks"].to_i.positive? ? question["marks"].to_i : 1,
      "difficulty" => question["difficulty"].presence || mock_difficulty
    }

    if type == "mcq"
      options = Array(question["options"]).map(&:to_s).reject(&:blank?)
      raise GenerationError, :invalid_mcq_options if options.size != 4
      normalized["options"] = options
    end

    raise GenerationError, :incomplete_response if normalized["question"].blank?

    normalized
  end
end
