# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::ImportBatchIdJob
  def perform(index_class_name, repo_name, batch_id, options = {})
    Esse::AsyncIndexing::Actions::ImportBatchId.call(index_class_name, repo_name, batch_id, options)
  end
end
