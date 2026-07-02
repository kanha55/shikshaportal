# frozen_string_literal: true

require "net/http"
require "json"

class AiNoticeGeneratorService
  class GenerationError < StandardError; end

  CATEGORIES = %w[holiday fee exam event].freeze
  ANTHROPIC_MODEL = "claude-3-haiku-20240307"
  DAILY_CAP = 50

  def initialize(school:, rough_input:, category:, bilingual: false, language: "hi", cursor_client: nil)
    @school = school
    @rough_input = rough_input.to_s.strip
    @category = category.to_s
    @bilingual = bilingual
    @language = language.to_s
    @cursor_client = cursor_client
  end

  def call
    validate!

    payload = if cursor_api?
                call_cursor_api
              elsif anthropic_api?
                call_anthropic_api
              else
                mock_response
              end

    normalize_payload(payload)
  end

  def self.daily_usage_for(school)
    AiGenerationLog.where(school: school).where("created_at >= ?", Time.current.beginning_of_day).count
  end

  def self.daily_cap_reached?(school)
    daily_usage_for(school) >= DAILY_CAP
  end

  private

  attr_reader :school, :rough_input, :category, :bilingual, :language, :cursor_client

  def validate!
    raise GenerationError, "Rough input is required" if rough_input.blank?
    raise GenerationError, "Invalid category" unless CATEGORIES.include?(category)
    raise GenerationError, "Daily AI limit reached" if self.class.daily_cap_reached?(school)
  end

  def cursor_api?
    ENV["CURSOR_API_KEY"].present?
  end

  def anthropic_api?
    ENV["ANTHROPIC_API_KEY"].present?
  end

  def call_cursor_api
    client = cursor_client || CursorAgentClient.new
    text = client.complete(cursor_prompt)
    parse_json_payload(text)
  rescue CursorAgentClient::ApiError
    raise GenerationError, "AI service unavailable"
  end

  def call_anthropic_api
    uri = URI("https://api.anthropic.com/v1/messages")
    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = ENV.fetch("ANTHROPIC_API_KEY")
    request["anthropic-version"] = "2023-06-01"
    request["content-type"] = "application/json"
    request.body = {
      model: ANTHROPIC_MODEL,
      max_tokens: 1024,
      messages: [
        { role: "user", content: prompt }
      ]
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise GenerationError, "AI service unavailable"
    end

    body = JSON.parse(response.body)
    text = body.dig("content", 0, "text")
    raise GenerationError, "Empty AI response" if text.blank?

    parse_json_payload(text)
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError
    raise GenerationError, "AI service unavailable"
  end

  def cursor_prompt
    <<~PROMPT
      #{prompt}

      Important: respond with JSON only. Do not use tools, code, or markdown fences.
    PROMPT
  end

  def prompt
    output_mode = if bilingual
                    "Bilingual: write notice_title and notice_body in both Hindi and English (Hindi first, then English separated by a blank line). whatsapp_message should be short Hindi suitable for WhatsApp parents."
                  elsif language == "en"
                    "Write all output in English."
                  else
                    "Write all output in Hindi (Devanagari script)."
                  end

    <<~PROMPT
      You are an assistant for #{school.name}, a village school in India.
      Category: #{category}
      Admin rough idea: #{rough_input}

      #{output_mode}

      Return ONLY valid JSON with exactly these keys:
      {
        "notice_title": "formal notice title",
        "notice_body": "formal notice body for the school notice board (2-4 sentences)",
        "whatsapp_message": "short informal WhatsApp message for parents (max 2-3 sentences, include school name)"
      }
    PROMPT
  end

  def parse_json_payload(text)
    cleaned = text.strip
    cleaned = cleaned.gsub(/\A```json\s*|\A```\s*|\s*```\z/, "")
    JSON.parse(cleaned)
  end

  def mock_response
    hindi_title = case category
                  when "holiday" then "अवकाश सूचना"
                  when "fee" then "शुल्क सूचना"
                  when "exam" then "परीक्षा सूचना"
                  else "स्कूल सूचना"
                  end

    notice_body = if bilingual
                    "#{rough_input}\n\n#{rough_input} (English notice based on admin input for #{school.name}.)"
                  elsif language == "en"
                    "This is a formal notice for #{school.name}: #{rough_input}"
                  else
                    "#{school.name} की ओर से: #{rough_input}"
                  end

    {
      "notice_title" => bilingual ? "#{hindi_title} / #{category.capitalize} Notice" : hindi_title,
      "notice_body" => notice_body,
      "whatsapp_message" => "प्रिय अभिभावक, #{school.name} — #{rough_input}। धन्यवाद।"
    }
  end

  def normalize_payload(payload)
    title = payload["notice_title"].to_s.strip
    body = payload["notice_body"].to_s.strip
    whatsapp = payload["whatsapp_message"].to_s.strip

    raise GenerationError, "Incomplete AI response" if title.blank? || body.blank? || whatsapp.blank?

    {
      notice_title: title,
      notice_body: body,
      whatsapp_message: whatsapp
    }
  end
end
