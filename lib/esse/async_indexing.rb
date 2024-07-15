# frozen_string_literal: true

require "esse"
# require "faktory_worker_ruby"
# require "esse-redis_storage"
require "forwardable"
require "securerandom"

module Esse
  module AsyncIndexing
  end
end

require_relative "async_indexing/version"
require_relative "async_indexing/config"

Esse::Config.__send__ :include, Esse::AsyncIndexing::Config
