# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class BulkImport
    def self.call(index_class_name, repo_name, ids, options = {})
      ids = Array(ids)
      return if ids.empty?

      _index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      kwargs = Esse::HashUtils.deep_transform_keys(options, &:to_sym)
      kwargs[:context] ||= {}
      kwargs[:context][:id] = ids
      repo_class.import(**kwargs)
    end
  end
end
