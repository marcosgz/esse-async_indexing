# frozen_string_literal: true

require "esse/cli/index/base_operation"

class Esse::AsyncIndexing::CLI::AsyncImport < Esse::CLI::Index::BaseOperation
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

        repo.batch_ids.each do |batch|
          # @TODO: Implement the async import
        end
      end
    end
  end

  private

  def options
    @options.slice(*@options.keys - Esse::CLI_IGNORE_OPTS - [:repo])
  end

  def validate_options!
    validate_indices_option!
  end
end
