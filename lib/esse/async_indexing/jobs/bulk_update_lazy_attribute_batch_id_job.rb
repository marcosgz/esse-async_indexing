# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeBatchIdJob
  def perform(index_class_name, repo_name, attribute_name, batch_id, options = {})
    Esse::AsyncIndexing::Actions::UpdateLazyAttributeBatchId.call(index_class_name, repo_name, attribute_name, batch_id, options)
  end
end
