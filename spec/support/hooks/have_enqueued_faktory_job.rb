# frozen_string_literal: true

module Hooks
  module AsyncIndexingJobs
    def self.included(base)
      base.before do |example|
        if example.metadata[:async_indexing_job]
          Esse::AsyncIndexing::Testing.enable!
        end
      end

      base.after do |example|
        if example.metadata[:async_indexing_job]
          Esse::AsyncIndexing::Jobs.clear
          Esse::AsyncIndexing::Testing.enable!
        end
      end
    end
  end
end

RSpec::Matchers.define :have_enqueued_async_indexing_job do |*expected_arguments|
  match do |job_class|
    @jobs = Esse::AsyncIndexing::Jobs.jobs_for(class_name: job_class, service: @service)
    if expected_arguments.any?
      @jobs.map { |h| h["args"] }.include? expected_arguments
    else
      @jobs.any?
    end
  end

  chain :on do |service|
    @service = service
  end

  def formatted_jobs(arr)
    arr.map do |json|
      "* #{json["__class_name__"]} with arguments (#{json["args"].map(&:inspect).join(", ")})"
    end.join("\n")
  end

  failure_message do |job_class|
    if expected_arguments.any?
      msg = "expected #{job_class} to have an enqueued job with arguments #{expected_arguments.inspect}#{%( on #{@service}) if @service} but it did not."
      if @jobs.any?
        msg << "\nEnqueued jobs:\n#{formatted_jobs(@jobs)}"
      end
      msg
    else
      "expected #{job_class} to have an enqueued job but it did not"
    end
  end

  failure_message_when_negated do |job_class|
    if expected_arguments.any?
      msg = "expected #{job_class} not to have an enqueued job with arguments #{expected_arguments.inspect}#{%( on #{@service}) if @service} but it did."
      if @jobs.any?
        msg << "\nEnqueued jobs:\n#{formatted_jobs(@jobs)}"
      end
      msg
    else
      "expected #{job_class} not to have an enqueued job but it did"
    end
  end

  description do
    if expected_arguments.any?
      "have an enqueued job with arguments #{expected_arguments.inspect} on #{@service || "any service"}"
    else
      "have an enqueued job"
    end
  end
end

RSpec.configure do |config|
  config.include Hooks::AsyncIndexingJobs
end
