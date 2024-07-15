# frozen_string_literal: true

class Esse::AsyncIndexing::Actions::UpsertDocument
  DOC_ARGS = %i[lazy_attributes]
  OPERATIONS = %w[index update delete]

  def self.call(index_class_name, repo_name, document_id, operation = "index", options = {})
    unless OPERATIONS.include?(operation)
      raise ArgumentError, "operation must be one of #{OPERATIONS.join(', ')}"
    end

    index_class = Object.const_get(index_class_name)
    repo_class = index_class.repo(repo_name) || raise(ArgumentError, "repo #{repo_name} not found in #{index_class_name}")
    bulk_opts = options.transform_keys(&:to_sym)
    bulk_opts.delete_if { |k, _| DOC_ARGS.include?(k) }
    find_opts = options.slice(*DOC_ARGS)

    doc = nil
    unless operation == "delete"
      doc = repo_class.documents(**find_opts, id: document_id).first
      index_class.send(operation, doc, **bulk_opts) if doc
    end
    return :indexed if doc

    index_class.delete(id: document_id, **bulk_opts)
    :deleted
  end
end
