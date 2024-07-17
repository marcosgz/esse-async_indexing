# frozen_string_literal: true

module Esse
  module AsyncIndexing
    class Testing
      class << self
        def enable!
          Thread.current[:esse_async_indexing_testing] = true
        end

        def disable!
          Thread.current[:esse_async_indexing_testing] = false
        end

        def enabled?
          Thread.current[:esse_async_indexing_testing] == true
        end

        def disabled?
          !enabled?
        end
      end
    end
  end
end

Esse::AsyncIndexing::Testing.disable!

module Esse::AsyncIndexing::Jobs
  class << self
    def jobs
      @jobs ||= []
    end

    def push(job)
      jobs.push(job)
    end

    def clear
      jobs.clear
    end

    def size
      jobs.size
    end

    def jobs_for(service: nil, class_name: nil)
      filtered = jobs
      if service
        filtered = filtered.select { |job| job["service"] == service.to_s }
      end
      if class_name
        filtered = filtered.select { |job| job["__class_name__"] == class_name.to_s }
      end
      filtered
    end
  end
end

module Esse::AsyncIndexing::JobsInterceptorAdapter
  def push
    return super unless Esse::AsyncIndexing::Testing.enabled?

    normalize_before_push
    test_payload = @payload.dup
    if @payload["jobtype"]
      test_payload["service"] = "faktory"
      test_payload["__class_name__"] = @payload["jobtype"]
    else
      test_payload["service"] = "sidekiq"
      test_payload["__class_name__"] = @payload["class"]
    end
    Esse::AsyncIndexing::Jobs.push(test_payload)
  end
end

Esse::AsyncIndexing::SERVICES.each_value do |adapter|
  adapter.prepend(Esse::AsyncIndexing::JobsInterceptorAdapter)
end
