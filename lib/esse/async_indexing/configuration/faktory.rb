# frozen_string_literal: true

module Esse::AsyncIndexing
  class Configuration::Faktory < Configuration::Base
    def initialize
      self.workers = {}
      super
    end

    def workers=(value)
      super

      Esse::AsyncIndexing::Workers::Faktory::DEFAULT.merge(value).each do |path, klass|
        @workers[klass] ||= {}
      end
    end
  end
end
