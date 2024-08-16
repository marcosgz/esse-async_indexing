# frozen_string_literal: true

module Esse
  module AsyncIndexing
    module Jobs
      DEFAULT = {
        "esse/async_indexing/jobs/bulk_update_lazy_attribute_batch_id_job" => "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeBatchIdJob",
        "esse/async_indexing/jobs/bulk_update_lazy_attribute_job" => "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob",
        "esse/async_indexing/jobs/document_delete_by_id_job" => "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob",
        "esse/async_indexing/jobs/document_index_by_id_job" => "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob",
        "esse/async_indexing/jobs/document_update_by_id_job" => "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob",
        "esse/async_indexing/jobs/document_upsert_by_id_job" => "Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob",
        "esse/async_indexing/jobs/import_all_job" => "Esse::AsyncIndexing::Jobs::ImportAllJob",
        "esse/async_indexing/jobs/import_batch_id_job" => "Esse::AsyncIndexing::Jobs::ImportBatchIdJob",
        "esse/async_indexing/jobs/import_ids_job" => "Esse::AsyncIndexing::Jobs::ImportIdsJob"
      }.freeze

      # The backend service may live in a different application, so they are not required by default.
      # That's why we have a separate structure to let enqueue jobs even without having the explicit worker class loaded.
      # This method will require all the internal jobs and configure them according to the defined options.
      def self.install!(service, **options)
        return if @installed_services&.include?(service.to_sym)

        DEFAULT.each do |job, const_name|
          Kernel.require(job)
          klass = Esse::AsyncIndexing::Jobs.const_get(const_name.split("::").last)
          klass.extend BackgroundJob.mixin(service, **options)
        end
        @installed_services = Array(@installed_services) << service.to_sym
      end
    end
  end
end
