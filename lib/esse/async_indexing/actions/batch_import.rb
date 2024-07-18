# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class BatchImport
    def self.call(index_class_name, repo_name, ids, options = {})
      ids = Array(ids)
      return if ids.empty?

      _index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      kwargs = options.transform_keys(&:to_sym)
      kwargs[:context] ||= {}
      kwargs[:context][:id] = ids
      repo_class.import(**kwargs)
    end
  end
end
