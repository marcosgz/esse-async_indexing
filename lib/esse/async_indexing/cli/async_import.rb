# frozen_string_literal: true

require "esse/cli/index/base_operation"

class Esse::AsyncIndexing::CLI::AsyncImport < Esse::CLI::Index::BaseOperation
  WORKER_NAME = "Esse::AsyncIndexing::Jobs::ImportBatchIdJob"

  def run
    validate_options!
    indices.each do |index|
      repos = if (repo = @options[:repo])
        [index.repo(repo)]
      else
        index.repo_hash.values
      end

      repos.each do |repo|
        unless Esse::AsyncIndexing.async_indexing_repo?(repo)
          raise Esse::CLI::InvalidOption, <<~MSG
            The #{repo} repository does not support async indexing. Make sure you have the `plugin :async_indexing` in your `#{index}` class and the :#{repo.repo_name} collection implements the `#each_batch_ids` method.
          MSG
        end

        enqueuer = if (caller = repo.async_indexing_jobs[:import])
          ->(ids) { caller.call(repo, :import, ids, **bulk_options) }
        else
          queue = Esse::RedisStorage::Queue.for(repo: repo)
          ->(ids) do
            batch_id = queue.enqueue(values: ids)
            Esse::AsyncIndexing.worker(WORKER_NAME, service: service_name)
              .with_args(repo.index.name, repo.repo_name, batch_id, bulk_options)
              .push
          end
        end

        repo.batch_ids.each(&enqueuer)
      end
    end
  end

  private

  def bulk_options
    @bulk_options ||= begin
      hash = @options.slice(*@options.keys - Esse::CLI_IGNORE_OPTS - [:repo, :service])
      hash.delete(:context) if hash[:context].nil? || hash[:context].empty?
      hash
    end
  end

  def validate_options!
    validate_indices_option!
  end

  def service_name
    (@options[:service] || Esse.config.async_indexing.services.first).to_sym
  end
end
