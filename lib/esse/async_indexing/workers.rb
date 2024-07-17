# frozen_string_literal: true

require_relative "worker"

module Esse
  module AsyncIndexing
    module Workers
      DEFAULT = {}

      def self.for(service, **options)
        require_relative "workers/#{service}"
        service = service.to_sym
        worker_options = options.merge(service: service)
        module_name = service.to_s.split(/_/i).collect! { |w| w.capitalize }.join
        mod = Esse::AsyncIndexing::Workers.const_get(module_name)
        mod.module_eval do
          define_method(:bg_worker_options) do
            worker_options
          end
        end
        mod
      end
    end
  end
end
