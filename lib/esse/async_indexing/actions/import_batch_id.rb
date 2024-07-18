# frozen_string_literal: true

module Esse::AsyncIndexing::Actions
  class ImportBatchId
    def self.call(index_class_name, repo_name, batch_id, options = {})
      _index_class, repo_class = CoerceIndexRepository.call(index_class_name, repo_name)
      queue = Esse::RedisStorage::Queue.for(repo: repo_class)

      kwargs = options.transform_keys(&:to_sym)
      kwargs[:context] ||= {}
      result = 0
      queue.fetch(batch_id) do |ids|
        kwargs[:context][:id] = ids
        result = repo_class.import(**kwargs)
      end
      result
    end
  end
end
