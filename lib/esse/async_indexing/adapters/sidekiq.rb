# frozen_string_literal: true

module Esse::AsyncIndexing
  module Adapters
    # This is a Sidekiq adapter that converts Esse::AsyncIndexing::Worker object into a sidekiq readable format
    # and then push the jobs into the service.
    class Sidekiq < Adapter
      attr_reader :worker, :queue

      def initialize(worker)
        @worker = worker
        @queue = worker.options.fetch(:queue, "default")

        @payload = worker.payload.merge(
          "class" => worker.worker_class,
          "retry" => worker.options.fetch(:retry, true),
          "queue" => @queue
        )
        @payload["created_at"] ||= Time.now.to_f
      end

      # Coerces the raw payload into an instance of Worker
      # @param payload [Hash] The job as json from redis
      # @options options [Hash] list of options that will be passed along to the Worker instance
      # @return [Esse::AsyncIndexing::Worker] and instance of Esse::AsyncIndexing::Worker
      def self.coerce_to_worker(payload, **options)
        raise(Error, "invalid payload") unless payload.is_a?(Hash)
        raise(Error, "invalid payload") unless payload["class"].is_a?(String)

        options[:retry] ||= payload["retry"] if payload.key?("retry")
        options[:queue] ||= payload["queue"] if payload.key?("queue")

        Esse::AsyncIndexing.worker(payload["class"], **options, service: :sidekiq).tap do |worker|
          worker.with_args(*Array(payload["args"])) if payload.key?("args")
          worker.with_job_jid(payload["jid"]) if payload.key?("jid")
          worker.created_at(payload["created_at"]) if payload.key?("created_at")
          worker.enqueued_at(payload["enqueued_at"]) if payload.key?("enqueued_at")
          worker.at(payload["at"]) if payload.key?("at")
        end
      end

      # Initializes adapter and push job into the sidekiq service
      #
      # @param worker [Esse::AsyncIndexing::Worker] An instance of Esse::AsyncIndexing::Worker
      # @return [Hash] Job payload
      # @see push method for more details
      def self.push(worker)
        new(worker).push
      end

      # Push sidekiq to the Sidekiq(Redis actually).
      #   * If job has the 'at' key. Then schedule it
      #   * Otherwise enqueue for immediate execution
      #
      # @return [Hash] Payload that was sent to redis
      def push
        normalize_before_push
        # Optimization to enqueue something now that is scheduled to go out now or in the past
        if (timestamp = @payload.delete("at")) && (timestamp > Time.now.to_f)
          Esse.config.async_indexing.sidekiq.redis_pool.with do |redis|
            redis.zadd(scheduled_queue_name, timestamp.to_f.to_s, to_json(@payload))
          end
        else
          Esse.config.async_indexing.sidekiq.redis_pool.with do |redis|
            redis.lpush(immediate_queue_name, to_json(@payload))
          end
        end
        @payload
      end

      protected

      def namespace
        Esse.config.async_indexing.sidekiq.namespace
      end

      def scheduled_queue_name
        "#{namespace}:schedule"
      end

      def immediate_queue_name
        "#{namespace}:queue:#{queue}"
      end

      def to_json(value)
        MultiJson.dump(value, mode: :compat)
      end

      def normalize_before_push
        @payload["enqueued_at"] = Time.now.to_f
      end
    end
  end
end
