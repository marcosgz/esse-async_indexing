# frozen_string_literal: true

module Esse::AsyncIndexing
  module ActiveRecordCallbacks
    class LazyUpdateAttribute < Callback
      LAZY_ATTR_WORKER = "Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob"

      attr_reader :attribute_name

      def initialize(service_name:, attribute_name:, with: nil, **kwargs)
        @attribute_name = attribute_name
        super(service_name: service_name, **kwargs)
      end

      def call(model)
        if (doc_ids = resolve_document_ids(model))
          BackgroundJob.job(service_name, LAZY_ATTR_WORKER)
            .with_args(repo.index.name, repo.repo_name, attribute_name.to_s, doc_ids, options)
            .push
        end

        true
      end
    end
  end
end
