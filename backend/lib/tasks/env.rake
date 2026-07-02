# frozen_string_literal: true

namespace :env do
  desc "Validate required environment variables for the current RAILS_ENV (T17)"
  task check: :environment do
    result = Shiksha::Env.validate!

    puts "Environment: #{Rails.env}"
    puts

    if result[:errors].any?
      puts "Errors:"
      result[:errors].each { |message| puts "  ✗ #{message}" }
      puts
    end

    if result[:warnings].any?
      puts "Warnings:"
      result[:warnings].each { |message| puts "  ⚠ #{message}" }
      puts
    end

    if result[:ok]
      required = Shiksha::Env.required_for(Rails.env)
      if required.any?
        puts "Required vars present: #{required.join(', ')}"
      else
        puts "No required vars for #{Rails.env} (development/test)."
      end
      puts "OK"
    else
      abort "Environment check failed"
    end
  end
end
