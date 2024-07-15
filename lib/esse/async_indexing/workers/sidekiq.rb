# frizen_string_literal: true

require_relative "shared_class_methods"

module Esse::AsyncIndexing
  module Workers
    module Sidekiq
      DEFAULT = {
        "esse/async_indexing/jobs/sidekiq_index_job" => "Esse::AsyncIndexing::Jobs::SidekiqIndexJob",
        "esse/async_indexing/jobs/sidekiq_batch_import_all" => "Esse::AsyncIndexing::Jobs::SidekiqBatchImportAll"
      }

      def self.extended(base)
        base.include(::Sidekiq::Worker) if defined?(::Sidekiq)
        base.extend SharedClassMethods
        base.extend ClassMethods
      end

      module ClassMethods
        def service_worker_options
          default_queue = Esse.config.async_indexing.sidekiq.workers.dig(name, :queue)
          default_retry = Esse.config.async_indexing.sidekiq.workers.dig(name, :retry)
          default_queue ||= ::Sidekiq.default_worker_options["queue"] if defined?(::Sidekiq)
          default_retry ||= ::Sidekiq.default_worker_options["retry"] if defined?(::Sidekiq)
          {
            queue: default_queue || "default",
            retry: default_retry || 15
          }
        end
      end
    end
  end
end
