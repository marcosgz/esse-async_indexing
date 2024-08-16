# frozen_string_literal: true

class Esse::AsyncIndexing::Jobs::ImportAllJob
  def perform(index_class_name, repo_name, options = {})
    Esse::AsyncIndexing::Actions::BulkImportAll.call(index_class_name, repo_name, options)
  end
end
