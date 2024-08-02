# frozen_string_literal: true

module Esse::AsyncIndexing
  module ActiveRecordCallbacks
    class OnUpdate < Callback
      def call(model)
        doc_id = resolve_document_id(model)
        return true unless doc_id

        kwargs = {service: service_name, repo: repo, id: doc_id}
        if with == :update
          repo.async_indexing_job_for(:update).call(**options, **kwargs, operation: :update)
        else
          repo.async_indexing_job_for(:index).call(**options, **kwargs, operation: :index)
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
