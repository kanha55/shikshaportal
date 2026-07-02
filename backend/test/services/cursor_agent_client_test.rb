# frozen_string_literal: true

require "test_helper"

class CursorAgentClientTest < ActiveSupport::TestCase
  test "complete returns assistant result text" do
    fake_client = Class.new(CursorAgentClient) do
      def create_agent(_prompt, model_id:)
        %w[bc-test run-test]
      end

      def wait_for_run(_agent_id, _run_id)
        '{"notice_title":"T","notice_body":"B","whatsapp_message":"W"}'
      end
    end

    result = fake_client.new(api_key: "test-key").complete("hello")
    assert_equal '{"notice_title":"T","notice_body":"B","whatsapp_message":"W"}', result
  end
end
