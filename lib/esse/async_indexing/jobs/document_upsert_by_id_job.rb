# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob
  def perform(index_class_name, repo_name, document_id, operation = "index", options = {})
    Esse::AsyncIndexing::Actions::UpsertDocument.call(index_class_name, repo_name, document_id, operation, options)
  end
end
