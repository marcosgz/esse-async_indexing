# frozen_string_literal: true

module Esse::AsyncIndexing
  module ActiveRecordCallbacks
    class LazyUpdateAttribute < Callback
      attr_reader :attribute_name

      def initialize(service_name:, attribute_name:, with: nil, **kwargs)
        @attribute_name = attribute_name
        super(service_name: service_name, **kwargs)
      end

      def call(model)
        if (doc_ids = resolve_document_ids(model))
          repo.async_indexing_job_for(:update_lazy_attribute).call(
            service: service_name,
            repo: repo,
            operation: :update_lazy_attribute,
            attribute: attribute_name,
            ids: doc_ids,
            **options
          )
        end

        true
      end
    end
  end
end
