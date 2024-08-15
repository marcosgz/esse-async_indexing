# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::ImportBatchIdJob
  LAZY_ATTR_WORKER = "Esse::AsyncIndexing::Jobs::BulkUpdateLazyDocumentAttributeJob"

  def perform(index_class_name, repo_name, batch_id, options = {})
    total, ids = Esse::AsyncIndexing::Actions::ImportBatchId.call(index_class_name, repo_name, batch_id, options)

    options = Esse::HashUtils.deep_transform_keys(options, &:to_s)
    return total if total.zero?
    return total if lazy_already_imported?(options)
    return total unless self.class.respond_to?(:background_job_service)

    _index_class, repo_class = Esse::AsyncIndexing::Actions::CoerceIndexRepository.call(index_class_name, repo_name)

    repo_class.lazy_document_attributes.each_key do |attr_name|
      queue = Esse::RedisStorage::Queue.for(repo: repo_class, attribute_name: attr_name)
      queue.enqueue(id: batch_id, values: ids)
      BackgroundJob.job(self.class.background_job_service, LAZY_ATTR_WORKER)
        .with_args(index_class_name, repo_name, attr_name.to_s, batch_id, options)
        .push
    end
    total
  end

  protected

  # The `import` action already eager or lazy load the document attributes when some of these options are set.
  def lazy_already_imported?(options)
    eager = options.delete("eager_include_document_attributes") || false
    lazy = options.delete("lazy_update_document_attributes") || false
    eager || lazy
  end
end
