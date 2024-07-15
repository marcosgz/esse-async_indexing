# frizen_string_literal: true

require_relative "shared_class_methods"

module Esse::AsyncIndexing
  module Workers
    module Faktory
      DEFAULT = {
        "esse/async_indexing/jobs/faktory_index_job" => "Esse::AsyncIndexing::Jobs::FaktoryIndexJob",
        "esse/async_indexing/jobs/faktory_batch_import_all" => "Esse::AsyncIndexing::Jobs::FaktoryBatchImportAll"
      }

      def self.extended(base)
        base.include(::Faktory::Job) if defined?(::Faktory)
        base.extend SharedClassMethods
        base.extend ClassMethods
      end

      module ClassMethods
        def service_worker_options
          default_queue = Esse.config.async_indexing.faktory.workers.dig(name, :queue)
          default_retry = Esse.config.async_indexing.faktory.workers.dig(name, :retry)
          default_queue ||= ::Faktory.default_job_options["queue"] if defined?(::Faktory)
          default_retry ||= ::Faktory.default_job_options["retry"] if defined?(::Faktory)
          {
            queue: default_queue || "default",
            retry: default_retry || 25
          }
        end
      end
    end
  end
end
