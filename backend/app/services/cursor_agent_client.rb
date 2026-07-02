# frozen_string_literal: true

require "net/http"
require "json"

class CursorAgentClient
  class ApiError < StandardError; end

  BASE_URL = "https://api.cursor.com"
  TERMINAL_STATUSES = %w[FINISHED ERROR CANCELLED EXPIRED].freeze
  POLL_INTERVAL = 1
  MAX_WAIT_SECONDS = 45

  def initialize(api_key: ENV["CURSOR_API_KEY"])
    @api_key = api_key.to_s.strip
    raise ApiError, "Cursor API key missing" if @api_key.blank?
  end

  def complete(prompt, model_id: ENV.fetch("CURSOR_AI_MODEL", "composer-2.5"))
    agent_id, run_id = create_agent(prompt, model_id: model_id)
    wait_for_run(agent_id, run_id)
  end

  private

  attr_reader :api_key

  def create_agent(prompt, model_id:)
    body = {
      prompt: { text: prompt },
      model: { id: model_id },
      name: "Shiksha notice draft"
    }

    response = request(:post, "/v1/agents", body)
    agent_id = response.dig("agent", "id")
    run_id = response.dig("run", "id") || response.dig("agent", "latestRunId")

    raise ApiError, "Invalid Cursor agent response" if agent_id.blank? || run_id.blank?

    [agent_id, run_id]
  end

  def wait_for_run(agent_id, run_id)
    deadline = Time.current + MAX_WAIT_SECONDS

    loop do
      run = request(:get, "/v1/agents/#{agent_id}/runs/#{run_id}")
      status = run["status"]

      return run["result"].to_s if status == "FINISHED"
      raise ApiError, "Cursor run failed" if %w[ERROR CANCELLED EXPIRED].include?(status)
      raise ApiError, "Cursor run timed out" if Time.current >= deadline

      sleep POLL_INTERVAL
    end
  end

  def request(method, path, body = nil)
    uri = URI("#{BASE_URL}#{path}")
    klass = method == :get ? Net::HTTP::Get : Net::HTTP::Post
    http_request = klass.new(uri)
    http_request["Authorization"] = "Bearer #{api_key}"
    http_request["Content-Type"] = "application/json"
    http_request.body = body.to_json if body

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
      http.request(http_request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "Cursor API error (#{response.code})"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError
    raise ApiError, "Invalid Cursor API response"
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError
    raise ApiError, "Cursor API unavailable"
  end
end
