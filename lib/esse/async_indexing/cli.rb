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
  option :eager_load_lazy_attributes, type: :string, default: nil, desc: "Comma separated list of lazy document attributes to include to the bulk index request. Or pass `true` to include all lazy attributes"
  option :lazy_update_document_attributes, type: :string, default: nil, desc: "Comma separated list of lazy document attributes to bulk update after the bulk index request Or pass `true` to include all lazy attributes"
  option :enqueue_lazy_attributes, type: :boolean, default: nil, desc: "Enqueue the lazy document attributes job after the bulk import. (default: true))"
  def async_import(*index_classes)
    opts = Esse::HashUtils.deep_transform_keys(options.to_h, &:to_sym)
    opts[:service] ||= Esse.config.async_indexing.services.first
    opts.delete(:lazy_update_document_attributes) if opts[:lazy_update_document_attributes] == "false"
    if (val = opts.delete(:eager_load_lazy_attributes)) && val != "false"
      opts[:eager_include_document_attributes] = (val == "true") ? true : val.split(",")
    end
    if (val = opts[:lazy_update_document_attributes])
      opts[:lazy_update_document_attributes] = (val == "true") ? true : val.split(",")
    end
    require "esse/async_indexing/cli/async_import"
    Esse::AsyncIndexing::CLI::AsyncImport.new(indices: index_classes, **opts).run
  end
end
