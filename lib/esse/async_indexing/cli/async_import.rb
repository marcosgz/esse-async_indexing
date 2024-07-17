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
          raise Esse::CLI::InvalidOption, format("The %<repo>p repository does not support async indexing", repo: repo)
        end

        enqueuer = if (caller = repo.async_indexing_jobs[:import])
          ->(ids) { caller.call(repo, :import, ids, **options) }
        else
          queue = Esse::RedisStorage::Queue.for(repo: repo)
          ->(ids) do
            batch_id = queue.enqueue(values: ids)
            Esse::AsyncIndexing.worker(WORKER_NAME)
              .with_args(repo.index.name, repo.name, batch_id, options)
              .push(to: service_name)
          end
        end

        repo.batch_ids.each(&enqueuer)
      end
    end
  end

  private

  def options
    @options.slice(*@options.keys - Esse::CLI_IGNORE_OPTS - [:repo, :service])
  end

  def validate_options!
    validate_indices_option!
  end

  def service_name
    @options[:service] || Esse.config.async_indexing.services.first
  end
end