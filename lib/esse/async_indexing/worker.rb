# frozen_string_literal: true

module Esse::AsyncIndexing
  class Worker
    attr_reader :options, :payload, :worker_class, :service

    attr_reader :arguments

    def initialize(worker_class, service: nil, **options)
      @worker_class = worker_class
      @service = service
      @options = options
      @payload = {}
    end

    def self.coerce(service:, payload:, **opts)
      Esse::AsyncIndexing::SERVICES.fetch(service).coerce_to_worker(payload, **opts)
    end

    %i[created_at enqueued_at].each do |method_name|
      define_method method_name do |value|
        @payload[method_name.to_s] =
          case value
          when Numeric then value.to_f
          when String then Time.parse(value).to_f
          when Time, DateTime then value.to_f
          else
            raise ArgumentError, format("The %<v>p is not a valid value for %<m>s.", v: value, m: method_name)
          end

        self
      end
    end

    # Adds arguments to the job
    # @return self
    def with_args(*args)
      @payload["args"] = args

      self
    end

    # Schedule the time when a job will be executed. Jobs which are scheduled in the past are enqueued for immediate execution.
    # @param timestamp [Numeric] timestamp, numeric or something that acts numeric.
    # @return self
    def in(timestamp)
      now = Time.now.to_f
      timestamp = Time.parse(timestamp) if timestamp.is_a?(String)
      int = timestamp.respond_to?(:strftime) ? timestamp.to_f : now + timestamp.to_f
      return self if int <= now

      @payload["at"] = int
      @payload["created_at"] = now

      self
    end
    alias_method :at, :in

    def with_job_jid(jid = nil)
      @payload["jid"] ||= jid || Esse::AsyncIndexing.jid

      self
    end

    # @return Response of service
    # @see Esse::AsyncIndexing::Adapters::** for more details
    def push
      unless Esse::AsyncIndexing::SERVICES.key?(service)
        raise Esse::AsyncIndexing::Error, format("Service %<service>p is not implemented. Please use one of #{Esse::AsyncIndexing::SERVICES.keys.map(&:inspect).join(" or ")}.", service: service)
      end
      @payload["created_at"] ||= Time.now.to_f
      worker_to_push = with_job_jid
      Esse::AsyncIndexing::SERVICES[service].push(worker_to_push)
    end

    def eql?(other)
      return false unless other.is_a?(self.class)

      worker_class == other.worker_class &&
        payload == other.payload &&
        options == other.options
    end
    alias_method :==, :eql?
  end
end
