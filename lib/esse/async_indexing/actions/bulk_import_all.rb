# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class BulkImportAll
    def self.call(index_class_name, repo_name, options = {})
      _index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      kwargs = Esse::HashUtils.deep_transform_keys(options, &:to_sym)
      repo_class.import(**kwargs)
    end
  end
end
