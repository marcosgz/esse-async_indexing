# frozen_string_literal: true

class Esse::AsyncIndexing::Actions::CoerceIndexRepository
  def self.call(index_class_name, repo_name)
    index_class = begin
      Object.const_get(index_class_name)
    rescue NameError
      raise(ArgumentError, "Index class #{index_class_name} not found")
    end

    repo_class = index_class.repo_hash[repo_name.to_s]
    repo_class ||= if repo_name.include?("::")
      index_class.repo_hash.map { |_, v| [v.to_s, v] }.to_h[repo_name]
    end
    if repo_class.nil?
      raise ArgumentError, <<~MSG
        No repo named "#{repo_name}" found in #{index_class_name}. Use the `repository` method to define one:

          repository :#{repo_name} do
            # collection ...
            # document ...
          end
      MSG
    end

    [index_class, repo_class]
  end
end
