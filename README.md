# Esse Async Indexing

This gem provides a way to [Esse](https://github.com/marcosgz/esse) index documents asynchronously using [Faktory](https://github.com/contribsys/faktory_worker_ruby) or [Sidekiq](https://github.com/sidekiq/sidekiq).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'esse-async_indexing'
```

And then execute:

```bash
$ bundle install
```

## Configuration

```ruby
Esse.configure do |config|
  # Setup Sidekiq
  require 'sidekiq'
  config.async_indexing.sidekiq do |sidekiq|
    sidekiq.redis = ConnectionPool.new(size: 10, timeout: 5) do
      Redis.new(url: ENV.fetch('REDIS_URL', 'redis://0.0.0.0:6379'))
    end
    # sidekiq.namespace = "sidekiq" # Sidekiq recommends using redis db number instead of namespace, but you can use it if you want
  end

  # Faktory
  require 'faktory_worker_ruby'
  config.async_indexing.faktory # No need to setup redis connection
end
```

### Configuration > Jobs Queues

Set the queues for each job and other options like retry, timeout, etc:

```ruby
Esse.configure do |config|
  config.async_indexing.sidekiq.jobs = {
    "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" => { queue: "batch_indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::ImportAllJob" => { queue: "batch_indexing", retry: false },
    "Esse::AsyncIndexing::Jobs::ImportIdsJob" => { queue: "batch_indexing", retry: 2 },
  }
  # or if you are using Faktory
  config.async_indexing.faktory.jobs = {
    "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" => { queue: "batch_indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::ImportAllJob" => { queue: "batch_indexing", retry: false },
    "Esse::AsyncIndexing::Jobs::ImportIdsJob" => { queue: "batch_indexing", retry: 2 },
  }
end
```

### Configuration > Tasks

To overwrite the default job that is enqueued for each operation. The default jobs are:
* :import => Esse::AsyncIndexing::Jobs::ImportIdsJob
* :index => Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob
* :update => Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob
* :delete => Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob
* :update_lazy_attribute => Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob

The operation can be set globally using the `task` method or per index using the `async_indexing_job` method.

Example above will first store ids in different storage and just enqueue job with the batch_id:

```ruby
Esse.configure do |config|
  config.async_indexing.task(:import) do |service:, repo:, operation:, ids:, **kwargs|
    batch_id = Esse::RedisStorage::Queue.for(repo: repo).enqueue(values: ids)
    ImportBatchIdJob.perform_later(repo.index.name, repo.repo_name, batch_id, **kwargs)
  end
end
```

Now when calling the async_import CLI command, it will push jobs to the `ImportBatchIdJob` instead of the standard `Esse::AsyncIndexing::Jobs::ImportIdsJob`.

## Index Configuration

To enable async indexing for an index, you need to add the `:async_indexing` plugin to the index. And the index collection must implement the `#each_batch_ids` method that yields an array of document ids.

```ruby
class GeosIndex < Esse::Index
  plugin :async_indexing

  repository :city do
    collection Collections::CityCollection
    document Documents::CityDocument
  end
end

class GeosIndex::Collections::CityCollection < Esse::Collection
  def each
    # implement the each method as usual
  end

  def each_batch_ids
    ::City.select(:id).except(:includes, :preload).find_in_batches(**batch_options) do |rows|
      yield(rows.map(&:id))
    end
  end
end
```

## CLI Commands

This gem includes the `async_import` command to import documents asynchronously.

```bash
$ bundle exec esse index help async_import
$ bundle exec esse index async_import GeosIndex --suffix="20240101" --service="sidekiq" --repo="city"
```


## Workers/Jobs

The gem provides a few jobs to index, update, upsert and delete document or batch of documents with given ids. The sidekiq or faktory job does not need to live in the same application that enqueues the job. The job can be in a separate application that only runs the job process. This gem has its own DSL to push jobs.

But for make sure to require the jobs in the job application by calling `install!`

```ruby
Esse::AsyncIndexing::Jobs.install!(:faktory)
Esse::AsyncIndexing::Jobs.install!(:sidekiq)
```


### Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob

Fetch a document from `GeosIndex.repo(:city)` collection using the given id and index it

```ruby
BackgroundJob.sidekiq("Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob").with_args("GeosIndex", "city", city.id, "suffix" => "20240101")
.push
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob

Fetch a document from `GeosIndex.repo(:city)` collection using the given id and update it

```ruby
BackgroundJob.sidekiq("Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob").with_args("GeosIndex", "city", city.id, "suffix" => "20240101")
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob

Fetch a document from `GeosIndex.repo(:city)` collection using the given id and upsert it

```ruby
BackgroundJob.sidekiq("Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob").with_args("GeosIndex", "city", city.id, "suffix" => "20240101")
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.


### Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob

Delete a document from the index using the given id

```ruby
BackgroundJob.sidekiq("Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob").with_args("GeosIndex", "city", city.id, "suffix" => "20240101")
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::ImportAllJob

Import all documents from the `GeosIndex.repo(:city)` collection where `state_abbr` is "IL"

```ruby
BackgroundJob.sidekiq("Esse::AsyncIndexing::Jobs::ImportAllJob").with_args("GeosIndex", "city", "context" => { "state_abbr" => "IL"}, "suffix" => "20240101")
```

**Note:** Suffix and import context are optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::ImportIdsJob

Import a batch of documents from the `GeosIndex.repo(:city)` collection using the given ids

```ruby
BackgroundJob.sidekiq("Esse::AsyncIndexing::Jobs::ImportIdsJob").with_args("GeosIndex", "city", city_ids, "suffix" => "20240101")
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob

Update a lazy attribute of a document from the index using the given id

```ruby
BackgroundJob.sidekiq("Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob").with_args("GeosIndex", "city", "total_schools", [city.id], "suffix" => "20240101")
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Custom Jobs

To implement a custom job :import, :index, :update or :delete documents, you need to define them using the `async_indexing_job` method in the index repository.

```ruby
class GeosIndex < Esse::Index
  plugin :async_indexing

  repository :city do
    collection Collections::CityCollection
    document Documents::CityDocument
    async_indexing_job(:import) do |service:, repo:, operation:, ids:, **kwargs|
      GeosCityImportJob.perform_later(ids, **kwargs)
    end
    async_indexing_job(:index, :update, :delete)  do |service:, repo:, operation:, id:, **kwargs|
      GeosCityUpsertJob.perform_later(id, **kwargs)
    end
  end
end
```

## Extras

You may want to use `async_indexing_callback` or `async_update_lazy_attribute_callback` callbacks along with the ActiveRecord models to automatically index, update, upsert or delete documents or attributes when the model is created, updated or destroyed.

This functionality require the [esse-active_record](https://github.com/marcosgz/esse-active_record) gem to be installed. Then require the `esse/asyn_indexing/active_record` file in the initializer.

```ruby
require 'esse/async_indexing/active_record'
```

Now you can use the `async_index_callback` or `async_update_lazy_attribute_callback` in the ActiveRecord models.

```diff
class City < ApplicationRecord
- include Esse::ActiveRecord::Model
+ include Esse::AsyncIndexing::ActiveRecord::Model

  belongs_to :state, optional: true

- index_callback('geos_index:city') { id }
- update_lazy_attribute_callback('geos_index:state', 'cities_count', if: :state_id?) { state_id }
+ async_index_callback('geos_index:city', service_name: :sidekiq) { id }
+ async_update_lazy_attribute_callback('geos_index:state', 'cities_count', if: :state_id?, service_name: :sidekiq) { state_id }
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake none` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosgz/esse-async_indexing.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
