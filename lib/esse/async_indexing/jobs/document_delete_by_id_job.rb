# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob
  def perform(index_class_name, repo_name, document_id, options = {})
    Esse::AsyncIndexing::Actions::DeleteDocument.call(index_class_name, repo_name, document_id, options)
  end
end
