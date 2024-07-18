# frozen_string_literal: true

require_relative "worker"

module Esse
  module AsyncIndexing
    module Workers
      DEFAULT = {
        "esse/async_indexing/jobs/document_delete_by_id_job" => "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob",
        "esse/async_indexing/jobs/document_index_by_id_job" => "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob",
        "esse/async_indexing/jobs/document_update_by_id_job" => "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob",
        "esse/async_indexing/jobs/document_upsert_by_id_job" => "Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob",
        "esse/async_indexing/jobs/import_all_job" => "Esse::AsyncIndexing::Jobs::ImportAllJob",
        "esse/async_indexing/jobs/import_batch_id_job" => "Esse::AsyncIndexing::Jobs::ImportBatchIdJob",
        "esse/async_indexing/jobs/update_lazy_document_attribute_job" => "Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob"
      }

      # The backend service may live in a different application, so they are not required by default.
      # That's why we have a separate structure to let enqueue jobs even without having the explicit worker class loaded.
      # This method will require all the internal jobs and configure them according to the defined options.
      def self.install!(service, **options)
        return if @installed_services&.include?(service.to_sym)

        DEFAULT.each do |job, worker_name|
          Kernel.require(job)
          worker = Esse::AsyncIndexing::Jobs.const_get(worker_name.split("::").last)
          worker.extend(self.for(service, **options))
        end
        @installed_services = Array(@installed_services) << service.to_sym
      end

      def self.for(service, **options)
        require_relative "workers/#{service}"
        service = service.to_sym
        worker_options = options.merge(service: service)
        module_name = service.to_s.split(/_/i).collect! { |w| w.capitalize }.join
        mod = Esse::AsyncIndexing::Workers.const_get(module_name)
        mod.module_eval do
          define_method(:bg_worker_options) do
            worker_options
          end
        end
        mod
      end
    end
  end
end
