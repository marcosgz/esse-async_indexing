# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class BulkUpdateLazyDocumentAttribute
    def self.call(index_class_name, repo_name, attr_name, batch_id, options = {})
      _index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      queue = Esse::RedisStorage::Queue.for(repo: repo_class, attribute_name: attr_name)

      kwargs = options.transform_keys(&:to_sym)

      attr_name = repo_class.lazy_document_attributes.keys.find { |key| key.to_s == attr_name.to_s }
      updated_ids = []
      queue.fetch(batch_id) do |ids|
        updated_ids = ids
        repo_class.update_documents_attribute(attr_name, ids, **kwargs)
      end
      updated_ids
    end
  end
end
