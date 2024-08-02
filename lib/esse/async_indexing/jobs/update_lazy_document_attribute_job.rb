# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob
  def perform(index_class_name, repo_name, attribute_name, ids, options = {})
    Esse::AsyncIndexing::Actions::UpdateLazyDocumentAttribute.call(index_class_name, repo_name, attribute_name, ids, options)
  end
end
