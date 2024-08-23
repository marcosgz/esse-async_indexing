# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class BulkDelete
    def self.call(index_class_name, repo_name, ids, options = {})
      docs = Esse::LazyDocumentHeader.coerce_each(ids)
      return if docs.empty?

      index_class, _repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      bulk_opts = Esse::HashUtils.deep_transform_keys(options, &:to_sym)
      index_class.bulk(**bulk_opts, delete: docs.map(&:doc_header))
      docs.size
    end
  end
end
