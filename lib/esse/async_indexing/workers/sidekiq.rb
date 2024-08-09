# frizen_string_literal: true

require_relative "shared_class_methods"

module Esse::AsyncIndexing
  module Workers
    module Sidekiq
      def self.extended(base)
        base.include(::Sidekiq::Worker) if defined?(::Sidekiq)
        base.extend SharedClassMethods
        base.extend ClassMethods
      end

      module ClassMethods
        def service_worker_options
          default_queue = Esse.config.async_indexing.sidekiq.workers.dig(name, :queue)
          default_retry = Esse.config.async_indexing.sidekiq.workers.dig(name, :retry)
          if defined?(::Sidekiq)
            default_queue ||= ::Sidekiq.default_job_options["queue"] if ::Sidekiq.respond_to?(:default_job_options)
            default_queue ||= ::Sidekiq.default_worker_options["queue"] if ::Sidekiq.respond_to?(:default_worker_options)
            default_retry ||= ::Sidekiq.default_job_options["retry"] if ::Sidekiq.respond_to?(:default_job_options)
            default_retry ||= ::Sidekiq.default_worker_options["retry"] if ::Sidekiq.respond_to?(:default_worker_options)
          end
          {
            queue: default_queue || "default",
            retry: default_retry || 15
          }
        end
      end
    end
  end
end
