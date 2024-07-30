# frozen_string_literal: true

module Esse::AsyncIndexing
  module ActiveRecordCallbacks
    class Callback < ::Esse::ActiveRecord::Callback
      attr_reader :service_name

      def initialize(service_name:, with: nil, **kwargs)
        @service_name = service_name
        @with = with
        super(**kwargs)
      end

      protected

      def resolve_document_id(model)
        resolve_document_ids(model).first
      end

      def resolve_document_ids(model)
        ::Esse::ArrayUtils.wrap(block_result || model).map do |record|
          record.is_a?(::ActiveRecord::Base) ? record.id : record
        end.compact
      end
    end
  end
end
