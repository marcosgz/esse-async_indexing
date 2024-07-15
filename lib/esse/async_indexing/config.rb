# frozen_string_literal: true

require_relative "configuration"
require_relative "configuration/base"
require_relative "configuration/faktory"
require_relative "configuration/sidekiq"

module Esse
  module AsyncIndexing
    module Config
      def self.included(base)
        base.__send__(:include, InstanceMethods)
      end

      module InstanceMethods
        def async_indexing
          @async_indexing ||= AsyncIndexing::Configuration.new
          if block_given?
            yield @async_indexing
          else
            @async_indexing
          end
        end
      end
    end
  end
end
