# frozen_string_literal: true

require "test_helper"

class AiNoticeGeneratorServiceTest < ActiveSupport::TestCase
  setup do
    @school = School.find_by!(subdomain: "greenvalley")
  end

  test "uses cursor client when key is configured" do
    fake_client = Object.new
    fake_client.define_singleton_method(:complete) do |_prompt, model_id: nil|
      {
        "notice_title" => "Holiday Notice",
        "notice_body" => "School closed tomorrow.",
        "whatsapp_message" => "School closed tomorrow."
      }.to_json
    end

    with_env("CURSOR_API_KEY" => "cursor_test_key", "ANTHROPIC_API_KEY" => nil) do
      result = AiNoticeGeneratorService.new(
        school: @school,
        rough_input: "kal school band",
        category: "holiday",
        cursor_client: fake_client
      ).call

      assert_equal "Holiday Notice", result[:notice_title]
      assert_equal "School closed tomorrow.", result[:notice_body]
    end
  end

  test "falls back to mock when cursor fails and anthropic is unset" do
    fake_client = Object.new
    fake_client.define_singleton_method(:complete) do |_prompt, model_id: nil|
      raise CursorAgentClient::ApiError, "Cursor API error (401)"
    end

    with_env("CURSOR_API_KEY" => "cursor_test_key", "ANTHROPIC_API_KEY" => nil) do
      result = AiNoticeGeneratorService.new(
        school: @school,
        rough_input: "kal school band",
        category: "holiday",
        cursor_client: fake_client
      ).call

      assert result[:notice_title].present?
      assert_includes result[:notice_body], "kal school band"
    end
  end

  private

  def with_env(updates)
    previous = updates.keys.index_with { |key| ENV[key] }
    updates.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end
end
