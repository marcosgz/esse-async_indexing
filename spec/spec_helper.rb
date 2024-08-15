# frozen_string_literal: true

require "bundler/setup"
require "pry"
require "opensearch-ruby"
require "esse/rspec"
require "esse/async_indexing"
require "support/hooks/timecop"
require "support/hooks/have_enqueued_faktory_job"
require "support/webmock"

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
    Esse.config.async_indexing.reset!
  end

  def setup_esse_client!
    Esse.configure do |config|
      config.cluster do |cluster|
        cluster.client = opensearch_client
      end
    end
  end

  def opensearch_client
    OpenSearch::Client.new.tap do |client|
      client.instance_variable_set(:@verified, true)
      client.define_singleton_method(:info) do
        {"version" => {"number" => "7.8.0", "distribution" => "opensearch"}}
      end
    end
  end
end
