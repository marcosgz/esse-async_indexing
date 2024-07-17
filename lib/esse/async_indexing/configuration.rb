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

      def faktory
        @faktory ||= begin
          services.add(:faktory)
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
          services.add(:sidekiq)
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
