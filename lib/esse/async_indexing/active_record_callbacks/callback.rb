# frozen_string_literal: true

module Esse::AsyncIndexing
  module ActiveRecordCallbacks
    class Callback < ::Esse::ActiveRecord::Callback
      attr_reader :service_name

      def initialize(service_name:, with: nil, **kwargs, &block)
        @service_name = service_name
        @with = with
        super(**kwargs, &block)
      end

      protected

      def resolve_document_id(model)
        ::Esse::ArrayUtils.wrap(block_result || model).map do |record|
          record.is_a?(::ActiveRecord::Base) ? record.id : record
        end.compact.first
      end
    end
  end
end
