# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class BulkUpdateLazyAttribute
    def self.call(index_class_name, repo_name, attr_name, ids, options = {})
      _index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      kwargs = Esse::HashUtils.deep_transform_keys(options, &:to_sym)

      real_attr_name = repo_class.lazy_document_attribute_names(attr_name).first
      if real_attr_name.nil? # let the job fail? or log and return?
        Esse.logger.warn("Lazy attribute #{attr_name.inspect} not found in `#{repo_name}` repository of `#{index_class_name}` index.")
        return
      end

      repo_class.update_documents_attribute(real_attr_name, ids, **kwargs)
      ids
    end
  end
end
