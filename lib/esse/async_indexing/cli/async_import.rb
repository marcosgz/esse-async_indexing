# frozen_string_literal: true

require "esse/cli/index/base_operation"

class Esse::AsyncIndexing::CLI::AsyncImport < Esse::CLI::Index::BaseOperation
  WORKER_NAME = "Esse::AsyncIndexing::Jobs::ImportIdsJob"

  attr_reader :job_options, :service_name

  def initialize(indices:, job_options: {}, service: nil, **options)
    @job_options = job_options
    @service_name = (service || Esse.config.async_indexing.services.first)&.to_sym
    super(indices: indices, **options)
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

        repo.batch_ids(**bulk_options.fetch(:context, {})).each do |ids|
          kwargs = {
            service: service_name,
            repo: repo,
            operation: :import,
            ids: ids,
            **bulk_options
          }.tap do |hash|
            hash[:job_options] = job_options if job_options.any?
          end
          repo.async_indexing_job_for(:import).call(**kwargs)
        end
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
end
