# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class UpsertDocument
    DOC_ARGS = %i[eager_load_lazy_attributes preload_lazy_attributes]

    def self.call(index_class_name, repo_name, document_id, operation = "index", options = {})
      case operation
      when "delete"
        DeleteDocument.call(index_class_name, repo_name, document_id, options)
      when "update"
        result = UpdateDocument.call(index_class_name, repo_name, document_id, options)
        return result if result != :not_found
        DeleteDocument.call(index_class_name, repo_name, document_id, options)
      when "index"
        result = IndexDocument.call(index_class_name, repo_name, document_id, options)
        return result if result != :not_found
        DeleteDocument.call(index_class_name, repo_name, document_id, options)
      else
        raise ArgumentError, "operation must be one of index, update, delete"
      end
    end
  end
end
