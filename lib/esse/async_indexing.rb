# frozen_string_literal: true

require "esse"
require "esse-redis_storage"
require "forwardable"
require "securerandom"
require "time"
require "multi_json"
require "background_job"

module Esse
  module AsyncIndexing
    module Actions
    end

    module Jobs
    end
  end
end

require_relative "async_indexing/version"
require_relative "async_indexing/actions"
require_relative "async_indexing/config"
require_relative "async_indexing/errors"
require_relative "async_indexing/events"
require_relative "async_indexing/jobs"
require_relative "plugins/async_indexing"

module Esse::AsyncIndexing
  # @param worker_class [String] The worker class name
  # @param options [Hash] Options that will be passed along to the worker instance
  # @return [Esse::AsyncIndexing::Worker] An instance of worker
  def self.worker(worker_class, service:, **options)
    serv_name = service_name(service)
    BackgroundJob.job(serv_name, worker_class, **options)
  end

  def self.service_name(identifier = nil)
    identifier ||= Esse.config.async_indexing.services.first
    if identifier.nil?
      raise ArgumentError, "There are no async indexing services configured. Please configure at least one service or pass the service name as an argument."
    end
    unless (services = BackgroundJob::SERVICES).key?(identifier.to_sym)
      raise ArgumentError, "Invalid service: #{identifier.inspect}, valid services are: #{services.keys.join(", ")}"
    end

    identifier.to_sym
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

