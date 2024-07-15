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
  def async_import(*index_classes)
    opts = Esse::HashUtils.deep_transform_keys(options.to_h, &:to_sym)
    require "esse/async_indexing/cli/async_import"
    opts[:service] ||= Esse.config.async_indexing.services.first
    Esse::AsyncIndexing::CLI::AsyncImport.new(indices: index_classes, **opts).run
  end
end
