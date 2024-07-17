# frozen_string_literal: true

class Esse::AsyncIndexing::Configuration::Base
  class << self
    private

    def attribute_accessor(field, validator: nil, normalizer: nil, default: nil)
      normalizer ||= :"normalize_#{field}"
      validator ||= :"validate_#{field}"

      define_method(field) do
        unless instance_variable_defined?(:"@#{field}")
          return if default.nil?

          send(:"#{field}=", default.respond_to?(:call) ? default.call : default)
        end
        instance_variable_get(:"@#{field}")
      end

      define_method(:"#{field}=") do |value|
        value = send(normalizer, field, value) if respond_to?(normalizer, true)
        send(validator, field, value) if respond_to?(validator, true)

        instance_variable_set(:"@#{field}", value)
      end
    end
  end

  # A Hash with all workers definitions. The worker class name must be the main hash key
  # Example:
  #   "FaktoryIndexWorker":
  #     retry: false
  #     queue: "indexing"
  #     adapter: "faktory"
  #   "FaktoryBatchIndexWorker":
  #     retry: 5
  #     queue: "batch_index"
  #     adapter: "faktory"
  attribute_accessor :workers, default: {}

  def worker_options(class_name)
    class_name = class_name.to_s
    if strict? && !workers.key?(class_name)
      raise Esse::AsyncIndexing::NotDefinedWorkerError.new(class_name)
    end

    workers.fetch(class_name, {})
  end

  def strict?
    true
  end

  protected

  def normalize_workers(_, value)
    return unless value.is_a?(Hash)

    hash = Esse::AsyncIndexing::Workers::DEFAULT.values.map { |v| [v, {}] }.to_h
    value.each do |class_name, opts|
      hash[class_name.to_s] = Esse::HashUtils.deep_transform_keys(opts.to_h, &:to_sym)
    end
    hash
  end
end
