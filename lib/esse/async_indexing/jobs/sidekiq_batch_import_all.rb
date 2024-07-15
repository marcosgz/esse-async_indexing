# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::SidekiqBatchImportAll
  extend Esse::AsyncIndexing::Workers.for(:sidekiq, queue: "batch_indexing")

  def perform(index_class_name, repo_name, options = {})
    Esse::AsyncIndexing::Actions::BatchImportAll.call(index_class_name, repo_name, options)
  end
end
