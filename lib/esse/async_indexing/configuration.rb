# frozen_string_literal: true

module Esse
  module AsyncIndexing
    class Configuration
      extend Forwardable
      def_delegators :bg_job_config, :services

      def reset!
        @faktory = nil
        @sidekiq = nil
        bg_job_config.reset!
      end

      def faktory
        @faktory ||= bg_job_config.faktory.tap do |config|
          default_jobs.each { |job_class| config.jobs[job_class] ||= {} }
        end
        yield @faktory if block_given?
        @faktory
      end

      def sidekiq
        @sidekiq ||= bg_job_config.sidekiq.tap do |config|
          default_jobs.each { |job_class| config.jobs[job_class] ||= {} }
        end
        yield @sidekiq if block_given?
        @sidekiq
      end

      def config_for(service)
        case service.to_sym
        when :faktory then faktory
        when :sidekiq then sidekiq
        else raise ArgumentError, "Unknown service: #{service}"
        end
      end

      private

      def bg_job_config
        BackgroundJob.config
      end

      def default_jobs
        Esse::AsyncIndexing::Jobs::DEFAULT.values
      end
    end
  end
end
