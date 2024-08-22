# frozen_string_literal: true

require "esse/cli/index/base_operation"

class Esse::AsyncIndexing::CLI::AsyncUpdateLazyAttributes < Esse::CLI::Index::BaseOperation
  WORKER_NAME = "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob"

  attr_reader :attributes, :job_options, :service_name

  def initialize(indices:, attributes: nil, job_options: nil, service: nil, **options)
    super(indices: indices, **options)
    @attributes = Array(attributes)
    @job_options = job_options || {}
    @service_name = (service || Esse.config.async_indexing.services.first)&.to_sym
  end

  def run
    validate_options!
    indices.each do |index|
      unless Esse::AsyncIndexing.plugin_installed?(index)
        raise Esse::CLI::InvalidOption, <<~MSG
          The #{index} index does not support async indexing. Make sure you have the `plugin :async_indexing` in your `#{index}` class.
        MSG
      end

      repos = if (repo = @options[:repo])
        [index.repo(repo)]
      else
        index.repo_hash.values
      end

      repos.each do |repo|
        unless Esse::AsyncIndexing.async_indexing_repo?(repo)
          raise Esse::CLI::InvalidOption, <<~MSG
            The #{repo} repository does not support async indexing. Make sure the :#{repo.repo_name} collection of `#{index}` implements the `#each_batch_ids` method.
          MSG
        end

        attrs = repo_attributes(repo)
        next unless attrs.any?

        enqueuer = if repo.async_indexing_job?(:update_lazy_attribute)
          ->(ids) do
            attrs.each do |attribute|
              repo.async_indexing_job_for(:update_lazy_attribute).call(service: service_name, repo: repo, operation: :update_lazy_attribute, attribute: attribute, ids: ids, **bulk_options)
            end
          end
        else
          ->(ids) do
            attrs.each do |attribute|
              BackgroundJob.job(service_name, WORKER_NAME, **job_options)
                .with_args(repo.index.name, repo.repo_name, attribute.to_s, ids, Esse::HashUtils.deep_transform_keys(bulk_options, &:to_s))
                .push
            end
          end
        end

        repo.batch_ids(**bulk_options.fetch(:context, {})).each(&enqueuer)
      end
    end
  end

  private

  def bulk_options
    @bulk_options ||= begin
      hash = @options.slice(*@options.keys - Esse::CLI_IGNORE_OPTS - [:repo])
      hash.delete(:context) if hash[:context].nil? || hash[:context].empty?
      hash
    end
  end

  def validate_options!
    validate_indices_option!
  end

  def repo_attributes(repo)
    return repo.lazy_document_attributes.keys if attributes.empty?

    repo.lazy_document_attribute_names(attributes)
  end
end
