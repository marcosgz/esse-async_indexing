# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::ImportIdsJob
  LAZY_ATTR_WORKER = "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob"

  def perform(index_class_name, repo_name, ids, options = {})
    # This is specific to the AsyncIndexing plugin, can't pass to Esse import method
    enqueue_lazy = options.delete(:enqueue_lazy_attributes) if options.key?(:enqueue_lazy_attributes)
    enqueue_lazy = options.delete("enqueue_lazy_attributes") if options.key?("enqueue_lazy_attributes")
    enqueue_lazy = true if enqueue_lazy.nil?
    total = Esse::AsyncIndexing::Actions::BulkImport.call(index_class_name, repo_name, ids, options)
    options = Esse::HashUtils.deep_transform_keys(options, &:to_s)

    return total if total.zero?
    return total unless enqueue_lazy
    return total if lazy_already_imported?(options)
    return total unless self.class.respond_to?(:background_job_service)

    _index_class, repo_class = Esse::AsyncIndexing::Actions::CoerceIndexRepository.call(index_class_name, repo_name)

    repo_class.lazy_document_attributes.each_key do |attr_name|
      BackgroundJob.job(self.class.background_job_service, LAZY_ATTR_WORKER)
        .with_args(index_class_name, repo_name, attr_name.to_s, ids, options)
        .push
    end
    total
  end

  protected

  # The `import` action already eager or lazy load the document attributes when some of these options are set.
  def lazy_already_imported?(options)
    preload = options.delete("preload_lazy_attributes") || false
    eager = options.delete("eager_load_lazy_attributes") || false
    lazy = options.delete("update_lazy_attributes") || false
    preload || eager || lazy
  end
end
