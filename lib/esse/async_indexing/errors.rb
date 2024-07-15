# frozen_string_literal: true

module Esse::AsyncIndexing
  class Error < StandardError
  end

  class NotDefinedWorkerError < Error
    def initialize(worker_name)
      super("Worker `#{worker_name}` is not defined.")
    end
  end
end
