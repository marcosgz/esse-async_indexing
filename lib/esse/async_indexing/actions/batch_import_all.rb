# frozen_string_literal: true

class Esse::AsyncIndexing::Actions::BatchImportAll
  def self.call(index_class_name, repo_name, options = {})
    index_class = Object.const_get(index_class_name)
    repo_class = index_class.repo(repo_name) || raise(ArgumentError, "repo #{repo_name} not found in #{index_class_name}")
    kwargs = options.transform_keys(&:to_sym)
    repo_class.import(**kwargs)
  end
end
