# frozen_string_literal: true

module Esse
  module AsyncIndexing
    class ConfigService < Set
      def sidekiq?
        include?(:sidekiq)
      end

      def faktory?
        include?(:faktory)
      end
    end

    class Configuration
      def services
        @services ||= ConfigService.new
      end

      def reset!
        @services = nil
        bg_job_config.reset!
      end

      BackgroundJob::SERVICES.each_key do |service|
        define_method(service) do |&block|
          config_for(service, &block)
        end
      end

      def config_for(service)
        case service.to_sym
        when :faktory
          conf = bg_job_config.faktory
          unless services.faktory?
            default_jobs.each { |job_class| conf.jobs[job_class] ||= {} }
            services << :faktory
          end
          yield conf if block_given?
          conf
        when :sidekiq
          conf = bg_job_config.sidekiq
          unless services.sidekiq?
            default_jobs.each { |job_class| conf.jobs[job_class] ||= {} }
            services << :sidekiq
          end
          yield conf if block_given?
          conf
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
