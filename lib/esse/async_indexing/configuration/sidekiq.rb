# frozen_string_literal: true

module Esse::AsyncIndexing
  class Configuration::Sidekiq < Configuration::Base
    attribute_accessor :redis
    attribute_accessor :namespace

    def redis_pool
      @redis_pool ||= Esse::RedisStorage::Pool.new(redis)
    end
  end
end
