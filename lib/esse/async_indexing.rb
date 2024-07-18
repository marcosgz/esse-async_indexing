# frozen_string_literal: true

require "esse"
require "esse-redis_storage"
require "forwardable"
require "securerandom"
require "time"
require "multi_json"

module Esse
  module AsyncIndexing
    module Actions
    end

    module Jobs
    end

    module Workers
    end
  end
end

require_relative "async_indexing/version"
require_relative "async_indexing/actions"
require_relative "async_indexing/adapters"
require_relative "async_indexing/config"
require_relative "async_indexing/errors"
require_relative "async_indexing/workers"
require_relative "plugins/async_indexing"

module Esse::AsyncIndexing
  SERVICES = {
    sidekiq: Adapters::Sidekiq,
    faktory: Adapters::Faktory
  }

  # @param worker_class [String] The worker class name
  # @param options [Hash] Options that will be passed along to the worker instance
  # @return [Esse::AsyncIndexing::Worker] An instance of worker
  def self.worker(worker_class, service: nil, **options)
    service ||= Esse.config.async_indexing.services.first
    if service.nil? || SERVICES[service.to_sym].nil?
      raise ArgumentError, "Invalid service: #{service.inspect}, valid services are: #{SERVICES.keys.join(", ")}"
    end

    Worker.new(worker_class, **Esse.config.async_indexing.send(service).worker_options(worker_class).merge(options), service: service)
  end

  def self.jid
    SecureRandom.hex(12)
  end

  def self.async_indexing_repo?(repo)
    return false unless repo.is_a?(Class) && repo < Esse::Repository

    repo.respond_to?(:implement_batch_ids?) && repo.implement_batch_ids?
  end
end

Esse::Config.__send__ :include, Esse::AsyncIndexing::Config
if defined?(Esse::CLI)
  require_relative "async_indexing/cli"
end

# if defined?(Esse::ActiveRecord)
#   require_relative "async_indexing/active_record"
# end
