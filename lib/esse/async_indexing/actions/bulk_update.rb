# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class BulkUpdate

    def self.call(index_class_name, repo_name, ids, options = {})
      ids = Array(ids)
      return if ids.empty?

      index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      bulk_opts = Esse::HashUtils.deep_transform_keys(options, &:to_sym)
      find_opts = {}
      if (context = bulk_opts.delete(:context))
        find_opts.merge!(context)
      end
      if (val = bulk_opts.delete(:eager_load_lazy_attributes))
        find_opts[:eager_load_lazy_attributes] = val
      end
      if (val = bulk_opts.delete(:preload_lazy_attributes))
        find_opts[:preload_lazy_attributes] = val
      end
      find_opts[:id] = ids

      count = 0
      repo_class.each_serialized_batch(**find_opts) do |batch|
        index_class.cluster.may_update_type!(bulk_opts)
        index_class.bulk(**bulk_opts, update: batch)
        count += batch.size
      end

      count
    end
  end
end
