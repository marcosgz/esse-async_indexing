# frozen_string_literal: true

module Esse::AsyncIndexing
  module Adapters
    class Adapter
      # Push the worker job to the service
      # @param _worker [Esse::AsyncIndexing::Worker] An instance of background worker
      # @abstract Child classes should override this method
      def self.push(_worker)
        raise NotImplemented
      end

      # Coerces the raw payload into an instance of Worker
      # @param payload [Object] the object that should be coerced to a Worker
      # @options options [Hash] list of options that will be passed along to the Worker instance
      # @return [Esse::AsyncIndexing::Worker] and instance of Esse::AsyncIndexing::Worker
      # @abstract Child classes should override this method
      def self.coerce_to_worker(payload, **options)
        raise NotImplemented
      end
    end
  end
end
