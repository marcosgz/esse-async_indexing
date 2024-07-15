# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::SidekiqIndexJob
  extend Esse::AsyncIndexing::Workers.for(:sidekiq, queue: "indexing")

  def perform(index_repo_class_name, document_id, operation = "index", options = {})
    Esse::AsyncIndexing::Actions::UpsertDocument.call(index_repo_class_name, document_id, operation, options)
  end
end
