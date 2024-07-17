# frozen_string_literal: true

module Hooks
  module FaktoryJobs
    def self.included(base)
      base.before do |example|
        if example.metadata[:faktory]
          require "faktory_worker_ruby"
          require "faktory/testing"
          Faktory::Testing.fake!
        end
      end

      base.after do |example|
        if example.metadata[:faktory]
          Faktory::Testing.disable!
        end
      end
    end
  end
end

RSpec::Matchers.define :have_enqueued_faktory_job do |*expected_arguments|
  match do |job_class|
    if job_class.is_a?(String)
      klass = Object.const_defined?(job_class) ? Object.const_get(job_class) : Class.new { def perform(*); end; } # rubocop:disable Style/SingleLineMethods
      class_name = job_class
      job_class = Class.new(klass) do
        extend Esse::AsyncIndexing::Workers.for(:faktory)
      end
      job_class.define_singleton_method(:name) { class_name }
      job_class.define_singleton_method(:to_s) { class_name }
      job_class.define_singleton_method(:inspect) { class_name }
    end
    @job_class = job_class

    if expected_arguments.any?
      @job_class.jobs.map { |h| h["args"] }.include? expected_arguments
    else
      @job_class.jobs.any?
    end
  end

  def formatted_jobs(arr)
    arr.map do |json|
      "* #{json["jobtype"]} with arguments (#{json["args"].map(&:inspect).join(", ")})"
    end.join("\n")
  end

  failure_message do |job_class|
    if expected_arguments.any?
      <<~MSG
        expected #{job_class} to have an enqueued job with arguments #{expected_arguments.inspect} but it did not.
        Enqueued jobs:
        #{formatted_jobs(@job_class.jobs)}
      MSG
    else
      "expected #{job_class} to have an enqueued job but it did not"
    end
  end

  failure_message_when_negated do |job_class|
    if expected_arguments.any?
      <<~MSG
        expected #{job_class} not to have an enqueued job with arguments #{expected_arguments.inspect} but it did.
        Enqueued jobs:
        #{formatted_jobs(@job_class.jobs)}
      MSG
    else
      "expected #{job_class} not to have an enqueued job but it did"
    end
  end

  description do
    if expected_arguments.any?
      "have an enqueued job with arguments #{expected_arguments.inspect}"
    else
      "have an enqueued job"
    end
  end
end

RSpec.configure do |config|
  config.include Hooks::FaktoryJobs
end
