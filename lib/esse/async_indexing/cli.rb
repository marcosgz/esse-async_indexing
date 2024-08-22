# frozen_string_literal: true

require "esse/cli"

module Esse::AsyncIndexing
  module CLI
  end
end

Esse::CLI::Index.class_eval do
  desc "async_import *INDEX_CLASSES", "Async Import documents from the given classes into the index"
  option :repo, type: :string, default: nil, alias: "-r", desc: "Repository to use for import"
  option :suffix, type: :string, default: nil, aliases: "-s", desc: "Suffix to append to index name"
  option :context, type: :hash, default: {}, required: true, desc: "List of options to pass to the index class"
  option :service, type: :string, default: nil, alias: "-s", desc: "Service to use for async import: sidekiq, faktory"
  option :preload_lazy_attributes, type: :string, default: nil, desc: "Command separated list of lazy document attributes to preload using search API before the bulk import. Or pass `true` to preload all lazy attributes"
  option :eager_load_lazy_attributes, type: :string, default: nil, desc: "Comma separated list of lazy document attributes to include to the bulk index request. Or pass `true` to include all lazy attributes"
  option :update_lazy_attributes, type: :string, default: nil, desc: "Comma separated list of lazy document attributes to bulk update after the bulk index request Or pass `true` to include all lazy attributes"
  option :enqueue_lazy_attributes, type: :boolean, default: nil, desc: "Enqueue the lazy document attributes job after the bulk import. (default: true))"
  option :job_options, type: :hash, default: {}, desc: "List of options to pass to the background job. (Example: --job-options=queue:default)"
  def async_import(*index_classes)
    opts = Esse::HashUtils.deep_transform_keys(options.to_h, &:to_sym)
    opts[:service] ||= Esse.config.async_indexing.services.first
    %i[preload_lazy_attributes eager_load_lazy_attributes update_lazy_attributes].each do |key|
      if (val = opts.delete(key)) && val != "false"
        opts[key] = (val == "true") ? true : val.split(",")
      end
    end
    require "esse/async_indexing/cli/async_import"
    Esse::AsyncIndexing::CLI::AsyncImport.new(indices: index_classes, **opts).run
  end

  desc "async_update_lazy_attributes INDEX_CLASS", "Async update lazy attributes for the given index"
  option :repo, type: :string, default: nil, alias: "-r", desc: "Repository to use for import"
  option :suffix, type: :string, default: nil, aliases: "-s", desc: "Suffix to append to index name"
  option :context, type: :hash, default: {}, required: true, desc: "List of options to pass to the index class"
  option :service, type: :string, default: nil, alias: "-s", desc: "Service to use for async import: sidekiq, faktory"
  option :job_options, type: :hash, default: {}, desc: "List of options to pass to the background job. (Example: --job-options=queue:default)"
  def async_update_lazy_attributes(index_class, *attributes)
    opts = Esse::HashUtils.deep_transform_keys(options.to_h, &:to_sym)
    opts[:service] ||= Esse.config.async_indexing.services.first
    require "esse/async_indexing/cli/async_update_lazy_attributes"

    Esse::AsyncIndexing::CLI::AsyncUpdateLazyAttributes.new(indices: [index_class], attributes: attributes, **opts).run
  end
end
