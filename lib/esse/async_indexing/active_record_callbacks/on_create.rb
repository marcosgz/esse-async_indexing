# frozen_string_literal: true

module Esse::AsyncIndexing
  module ActiveRecordCallbacks
    class OnCreate < Callback
      def call(model)
        if (doc_id = resolve_document_id(model))
          repo.async_indexing_job_for(:index).call(**options, service: service_name, repo: repo, operation: :index, id: doc_id)
        end

        true
      end
    end
  end
end
