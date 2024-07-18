# frozen_string_literal: true

module Esse::AsyncIndexing
  module ActiveRecordCallbacks
    class OnCreate < Callback
      def call(model)
        if (doc_id = resolve_document_id(model))
          repo.async_indexing_job_for(:index).call(service_name, repo, :index, doc_id, **options)
        end

        true
      end
    end
  end
end
