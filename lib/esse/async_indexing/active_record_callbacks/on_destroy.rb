# frozen_string_literal: true

module Esse::AsyncIndexing
  module ActiveRecordCallbacks
    class OnDestroy < Callback
      def call(model)
        if (doc_id = resolve_document_id(model))
          repo.async_indexing_job_for(:delete).call(service_name, repo, :delete, doc_id, **options)
        end

        true
      end
    end
  end
end
