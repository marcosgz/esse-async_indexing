# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class IndexDocument
    DOC_ARGS = %i[lazy_attributes]

    def self.call(index_class_name, repo_name, document_id, options = {})
      index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      bulk_opts = options.transform_keys(&:to_sym)
      bulk_opts.delete_if { |k, _| DOC_ARGS.include?(k) }
      find_opts = options.slice(*DOC_ARGS)

      doc = repo_class.documents(**find_opts, id: document_id).first
      return :not_found unless doc

      index_class.index(doc, **bulk_opts)
      :indexed
    end
  end
end
