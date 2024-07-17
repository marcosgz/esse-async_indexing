# frozen_string_literal: true

class Esse::AsyncIndexing::Actions::ImportBatchId
  def self.call(index_class_name, repo_name, batch_id, options = {})
    index_class = Object.const_get(index_class_name)
    repo_class = index_class.repo(repo_name) || raise(ArgumentError, "repo #{repo_name} not found in #{index_class_name}")
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
