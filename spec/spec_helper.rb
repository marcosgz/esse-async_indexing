# frozen_string_literal: true

require "bundler/setup"
require "pry"
require "esse/rspec"
require "esse/async_indexing"
require "support/hooks/timecop"

MINUTE_IN_SECONDS = 60
HOUR_IN_SECONDS = MINUTE_IN_SECONDS * 60
DAY_IN_SECONDS = HOUR_IN_SECONDS * 24
WEEK_IN_SECONDS = DAY_IN_SECONDS * 7

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include Hooks::Timecop

  def reset_config!
    Esse.instance_variable_set(:@config, nil)
  end
end
