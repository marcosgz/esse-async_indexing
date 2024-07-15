# frozen_string_literal: true

require_relative "lib/esse/async_indexing/version"

Gem::Specification.new do |spec|
  spec.name = "esse-async_indexing"
  spec.version = Esse::AsyncIndexing::VERSION
  spec.authors = ["Marcos G. Zimmermann"]
  spec.email = ["mgzmaster@gmail.com"]

  spec.summary = "Esse extension to allow async indexing using Faktory or Sidekiq."
  spec.description = "Extends Esse to allow async indexing using Faktory or Sidekiq."
  spec.homepage = "https://github.com/marcosgz/esse-async_indexing"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/marcosgz/esse-async_indexing"
  spec.metadata["changelog_uri"] = "https://github.com/marcosgz/esse-async_indexing/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "esse", ">= 0.3.3"
  spec.add_dependency "multi_json", ">= 0.0.0"
  spec.add_dependency "esse-redis_storage", "~> 0.0.1"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "webmock"
end
