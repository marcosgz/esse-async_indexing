# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class UpdateLazyDocumentAttribute
    def self.call(index_class_name, repo_name, attr_name, ids, options = {})
      _index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      kwargs = Esse::HashUtils.deep_transform_keys(options, &:to_sym)

      attr_name = repo_class.lazy_document_attributes.keys.find { |key| key.to_s == attr_name.to_s }
      repo_class.update_documents_attribute(attr_name, ids, **kwargs)
      ids
    end
  end
end
