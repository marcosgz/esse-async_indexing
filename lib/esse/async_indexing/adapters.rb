# frozen_string_literal: true

module Esse
  module AsyncIndexing
    module Adapters
    end
  end
end

require_relative "adapters/adapter"
require_relative "adapters/sidekiq"
require_relative "adapters/faktory"
