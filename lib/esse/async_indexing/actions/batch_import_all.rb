# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class BatchImportAll
    def self.call(index_class_name, repo_name, options = {})
      _index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      kwargs = options.transform_keys(&:to_sym)
      repo_class.import(**kwargs)
    end
  end
end
