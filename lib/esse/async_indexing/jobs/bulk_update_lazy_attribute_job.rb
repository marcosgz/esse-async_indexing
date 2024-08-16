# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob
  def perform(index_class_name, repo_name, attribute_name, ids, options = {})
    Esse::AsyncIndexing::Actions::BulkUpdateLazyAttribute.call(index_class_name, repo_name, attribute_name, ids, options)
  end
end
