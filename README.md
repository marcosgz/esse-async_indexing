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
  config.redis = ConnectionPool.new(size: 10, timeout: 5) do
    Redis.new(url: ENV.fetch('REDIS_URL', 'redis://0.0.0.0:6379'))
  end

  # Setup Sidekiq
  require 'sidekiq'
  config.async_indexing.sidekiq do |sidekiq|
    sidekiq.namespace = "sidekiq"
    sidekiq.redis = ConnectionPool.new(size: 10, timeout: 5) do
      Redis.new(url: ENV.fetch('REDIS_URL', 'redis://0.0.0.0:6379'))
    end
  end

  # Faktory
  require 'faktory_worker_ruby'
  config.async_indexing.faktory # No need to setup redis connection
end
```

Optional worker configuration:

```ruby
Esse.configure do |config|
  config.async_indexing.sidekiq.workers = {
    "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::ImportAllJob" => { queue: "batch_indexing", retry: 3 },
    "Esse::AsyncIndexing::Jobs::ImportBatchIdJob" => { queue: "batch_indexing", retry: 3 },
    "Esse::AsyncIndexing::Jobs::BulkUpdateLazyDocumentAttributeJob" => { queue: "batch_indexing", retry: 3 },
    "Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob" => { queue: "indexing" },
  }
  # or if you are using Faktory
  config.async_indexing.faktory.workers = {
    "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob" => { queue: "indexing" },
    "Esse::AsyncIndexing::Jobs::ImportAllJob" => { queue: "batch_indexing", retry: 3 },
    "Esse::AsyncIndexing::Jobs::ImportBatchIdJob" => { queue: "batch_indexing", retry: 3 },
    "Esse::AsyncIndexing::Jobs::BulkUpdateLazyDocumentAttributeJob" => { queue: "batch_indexing", retry: 3 },
    "Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob" => { queue: "indexing" },
  }
end
```

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

The gem provides a few jobs to index, update, upsert and delete document or batch of documents with given ids. The sidekiq or faktory worker does not need to live in the same application that enqueues the job. The worker can be in a separate application that only runs the worker process. This gem has its own DSL to push jobs.

But for make sure to require the jobs in the worker application by calling `install!`

```ruby
Esse::AsyncIndexing::Workers.install!(:faktory)
Esse::AsyncIndexing::Workers.install!(:sidekiq)
```


### Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob

Fetch a document from `GeosIndex.repo(:city)` collection using the given id and index it

```ruby
Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob", service: :sidekiq).with_args("GeosIndex", "city", city.id, suffix: "20240101")
.push
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob

Fetch a document from `GeosIndex.repo(:city)` collection using the given id and update it

```ruby
Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob", service: :sidekiq).with_args("GeosIndex", "city", city.id, suffix: "20240101")
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob

Fetch a document from `GeosIndex.repo(:city)` collection using the given id and upsert it

```ruby
Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob", service: :sidekiq).with_args("GeosIndex", "city", city.id, suffix: "20240101")
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.


### Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob

Delete a document from the index using the given id

```ruby
Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob", service: :sidekiq).with_args("GeosIndex", "city", city.id, suffix: "20240101")
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::ImportAllJob

Import all documents from the `GeosIndex.repo(:city)` collection where `state_abbr` is "IL"

```ruby
Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::ImportAllJob", service: :sidekiq).with_args("GeosIndex", "city", context: {state_abbr: "IL"}, suffix: "20240101")
```

**Note:** Suffix and import context are optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::ImportBatchIdJob

Import a batch of documents from the `GeosIndex.repo(:city)` collection using a batch_id generated by the [esse-redis_storage](https://github.com/marcosgz/esse-redis_storage) gem. This is the job that the `async_import` command uses.

```ruby
batch_id = Esse::RedisStorage::Queue.for(repo: GeosIndex.repo(:city)).enqueue(values: big_list_of_uuids)
Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::ImportBatchIdJob", service: :sidekiq).with_args("GeosIndex", "city", batch_id, suffix: "20240101")
```
**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::BulkUpdateLazyDocumentAttributeJob

Update a lazy attribute of a document from the index using the given enqueued batch_id.

```ruby
batch_id = Esse::RedisStorage::Queue.for(repo: GeosIndex.repo(:city), attribute_name: "total_schools").enqueue(values: big_list_of_uuids)
Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::BulkUpdateLazyDocumentAttributeJob", service: :sidekiq).with_args("GeosIndex", "city", "total_schools", batch_id, suffix: "20240101")
```

**Note:** Suffix is optional, just an example of how to pass additional arguments to the job.

### Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob

Update a lazy attribute of a document from the index using the given id

```ruby
Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob", service: :sidekiq).with_args("GeosIndex", "city", "total_schools", [city.id], suffix: "20240101")
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
    async_indexing_job(:import) do |_service_name, _repo_class, _operation_name, ids, **kwargs|
      GeosCityImportJob.perform_later(ids, **kwargs)
    end
    async_indexing_job(:index, :update, :delete)  do |_service_name, _repo_class, _operation_name, id, **kwargs|
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
