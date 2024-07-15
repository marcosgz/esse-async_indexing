# frozen_string_literal: true

class Esse::AsyncIndexing::Actions::BatchImport
  def self.call(index_class_name, repo_name, ids, options = {})
    ids = Array(ids)
    return if ids.empty?

    index_class = Object.const_get(index_class_name)
    repo_class = index_class.repo(repo_name) || raise(ArgumentError, "repo #{repo_name} not found in #{index_class_name}")
    kwargs = options.transform_keys(&:to_sym)
    kwargs[:context] ||= {}
    kwargs[:context][:id] = ids
    repo_class.import(**kwargs)
  end
end
