# frozen_string_literal: true

module Esse
  module AsyncIndexing
    class Configuration
      def faktory
        @faktory ||= begin
          require_relative "jobs/faktory_index_job"
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
          require_relative "jobs/sidekiq_index_job"
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
