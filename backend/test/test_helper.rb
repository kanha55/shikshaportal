# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper

    parallelize(workers: :number_of_processors)

    setup do
      Rails.application.load_seed unless School.exists?(subdomain: "greenvalley")
    end
  end
end
