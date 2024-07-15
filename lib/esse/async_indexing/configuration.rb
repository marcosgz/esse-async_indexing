# frozen_string_literal: true

module Esse
  module AsyncIndexing
    class Configuration
      def faktory
        @faktory ||= Configuration::Faktory.new
        if block_given?
          yield @faktory
        else
          @faktory
        end
      end

      def sidekiq
        @sidekiq ||= Configuration::Sidekiq.new
        if block_given?
          yield @sidekiq
        else
          @sidekiq
        end
      end
    end
  end
end
