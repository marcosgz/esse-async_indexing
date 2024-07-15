# frozen_string_literal: true

module Esse
  module AsyncIndexing
    class Configuration
      def faktory
        @faktory ||= begin
          require_relative "workers/faktory"
          Esse::AsyncIndexing::Workers::Faktory::DEFAULT.each_key do |path|
            require path
          end
          Configuration::Faktory.new
        end
        if block_given?
          yield @faktory
        else
          @faktory
        end
      end

      def sidekiq
        @sidekiq ||= begin
          require_relative "workers/sidekiq"
          Esse::AsyncIndexing::Workers::Sidekiq::DEFAULT.each_key do |path|
            require path
          end
          Configuration::Sidekiq.new
        end
        if block_given?
          yield @sidekiq
        else
          @sidekiq
        end
      end
    end
  end
end
