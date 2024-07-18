# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class DeleteDocument
    DOC_ARGS = %i[lazy_attributes]

    def self.call(index_class_name, repo_name, document_id, options = {})
      index_class, _repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      bulk_opts = options.transform_keys(&:to_sym)
      bulk_opts.delete_if { |k, _| DOC_ARGS.include?(k) }

      index_class.delete(id: document_id, **bulk_opts)
      :deleted
    end
  end
end
