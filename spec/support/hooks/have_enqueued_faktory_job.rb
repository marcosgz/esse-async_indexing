# frozen_string_literal: true

require "background_job/testing"

module Hooks
  module BackgroundJobs
    def self.included(base)
      base.before do |example|
        ::BackgroundJob::Testing.enable!
      end

      base.after do |example|
        ::BackgroundJob::Jobs.clear
      end
    end
  end
end

module BackgroundJobFormatter
  module_function

  def args(args)
    return "(no arguments)" if args.empty?

    %[(#{args.map(&:inspect).join(", ")})]
  end

  def job(job)
    "* #{job.job_class} with arguments #{args(job.payload["args"])}"
  end

  def jobs(jobs)
    "Enqueued jobs:\n#{jobs.map { |j| job(j) }.join("\n")}"
  end
end

module EnqueueBackgroundJobMatcher
  class EnqueueBackgroundJob
    def initialize(job_class, **options)
      @job_class = job_class
      @options = options
    end

    def with_args(*args)
      @with_args = args
      self
    end
    alias_method :with, :with_args

    def matches?(proc)
      raise ArgumentError, "Only block syntax supported for enqueue_background_job" unless Proc === proc
      @job = BackgroundJob::Jobs::Sidekiq.new(@job_class, **@options)
      if @with_args
        @job = @job.with_args(*@with_args)
      end
      @enqueued_jobs = BackgroundJob::Jobs.jobs
      proc.call
      @enqueued_jobs.any? do |job|
        job.job_class == @job.job_class &&
          (@with_args.nil? || job.payload["args"] == @job.payload["args"])
      end
    end

    def failure_message
      msg = ["expected #{@job} to have been enqueued but it was not."]
      if @enqueued_jobs.any?
        msg << BackgroundJobFormatter.jobs(@enqueued_jobs)
      end
      msg.join("\n")
    end

    def failure_message_when_negated
      msg = ["expected #{@job} not to have been enqueued but it was."]
      if @enqueued_jobs.any?
        msg << BackgroundJobFormatter.jobs(@enqueued_jobs)
      end
      msg.join("\n")
    end

    def description
      if @args
        "have an enqueued job with arguments #{BackgroundJobFormatter.args(@args)}"
      else
        "have an enqueued job"
      end
    end

    def supports_block_expectations?
      true
    end
  end

  def enqueue_background_job(job_class, **options)
    EnqueueBackgroundJob.new(job_class, **options)
  end
end

RSpec::Matchers.define :have_enqueued_background_job do |*expected_arguments|
  supports_block_expectations

  match do |block|
    job_class = block.call
    @job = case @service
    when :faktory
      BackgroundJob::Jobs::Faktory.new(job_class)
    when :sidekiq
      BackgroundJob::Jobs::Sidekiq.new(job_class)
    else
      BackgroundJob::Jobs::Job.new(job_class)
    end
    @job = @job.with_args(*expected_arguments)
    @enqueued_jobs = BackgroundJob::Jobs.jobs
    @enqueued_jobs.any? do |job|
      job.job_class == @job.job_class &&
        job.payload["args"] == @job.payload["args"]
    end
  end

  chain :on do |service|
    @service = service
  end

  failure_message do |_block|
    if expected_arguments.any?
      msg = ["expected #{@job.job_class} to have an enqueued job with arguments #{BackgroundJobFormatter.args(expected_arguments)} but it did not."]
      if @enqueued_jobs.any?
        msg << BackgroundJobFormatter.jobs(@enqueued_jobs)
      end
      msg.join("\n")
    else
      "expected #{@job.job_class} to have an enqueued job but it did not"
    end
  end

  failure_message_when_negated do |_block|
    if expected_arguments.any?
      msg = ["expected #{@job.job_class} not to have an enqueued job with arguments #{BackgroundJobFormatter.args(expected_arguments)} but it did."]
      if @enqueued_jobs.any?
        msg << BackgroundJobFormatter.jobs(@enqueued_jobs)
      end
      msg.join("\n")
    else
      "expected #{@job.job_class} not to have an enqueued job but it did"
    end
  end

  description do
    if expected_arguments.any?
      "have an enqueued job with arguments #{BackgroundJobFormatter.args(expected_arguments)}"
    else
      "have an enqueued job"
    end
  end
end

module BackgroundJobsHelper
  def clear_enqueued_jobs
    ::BackgroundJob::Jobs.clear
  end
end

RSpec.configure do |config|
  config.include Hooks::BackgroundJobs
  config.include BackgroundJobsHelper
  config.include EnqueueBackgroundJobMatcher
end
