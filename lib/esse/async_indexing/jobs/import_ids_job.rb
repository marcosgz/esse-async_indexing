# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::ImportIdsJob
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

    index_class, repo_class = Esse::AsyncIndexing::Actions::CoerceIndexRepository.call(index_class_name, repo_name)
    return total unless Esse::AsyncIndexing.plugin_installed?(index_class)

    repo_class.lazy_document_attributes.each_key do |attr_name|
      repo_class.async_indexing_job_for(:update_lazy_attribute).call(
        **options,
        service: self.class.background_job_service,
        repo: repo_class,
        operation: :update_lazy_attribute,
        attribute: attr_name,
        ids: ids
      )
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
