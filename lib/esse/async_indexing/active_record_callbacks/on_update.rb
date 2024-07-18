# frozen_string_literal: true

module Esse::AsyncIndexing
  module ActiveRecordCallbacks
    class OnUpdate < Callback
      def call(model)
        doc_id = resolve_document_id(model)
        return true unless doc_id

        if with == :update
          repo.async_indexing_job_for(:update).call(service_name, repo, :update, doc_id, **options)
        else
          repo.async_indexing_job_for(:index).call(service_name, repo, :index, doc_id, **options)
        end

        true
      end

      protected

      def with
        @with || :index
      end
    end
  end
end
