# frozen_string_literal: true

require "spec_helper"
require "support/cli_helpers"
require "esse/cli"
require "esse/async_indexing/cli/async_import"

# rubocop:disable RSpec/ExpectActual
# rubocop:disable RSpec/AnyInstance
RSpec.describe "Esse::CLI::Index", type: :cli do
  describe "#async_import" do
    let(:index_collection_class) do
      Class.new(Esse::Collection) do
        def each_batch_ids
          yield([1, 2, 3])
        end
      end
    end

    def after
      reset_config!
    end

    context "when passing undefined or invalid index name" do
      it "raises an error if no index name is given" do
        expect {
          cli_exec(%w[index async_import])
        }.to raise_error(Esse::CLI::InvalidOption, /You must specify at least one index class/)
      end

      it "raises an error if given argument is not a valid index class" do
        expect {
          cli_exec(%w[index async_import Esse::Config])
        }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
      end

      it "raises an error if given argument is not defined" do
        expect {
          cli_exec(%w[index async_import NotDefinedIndexName])
        }.to raise_error(Esse::CLI::InvalidOption, /Unrecognized index class: "NotDefinedIndexName"/)
      end
    end

    context "when passing an index that does not support async indexing" do
      before do
        collection_class = index_collection_class
        stub_esse_index(:counties) do
          repository :county do
            collection collection_class
          end
        end
      end

      it "raises an error if the repository does not have the async_indexing plugin" do
        expect {
          cli_exec(%w[index async_import CountiesIndex])
        }.to raise_error(Esse::CLI::InvalidOption, /The CountiesIndex::County repository does not support async indexing/)
      end
    end

    context "when passing a index with single repository that supports async indexing", :async_indexing_job do
      before do
        collection_class = index_collection_class
        stub_esse_index(:cities) do
          plugin :async_indexing
          repository :city do
            collection collection_class
          end
        end
      end

      it "enqueues the faktory job for the given index when passing --service=faktory" do
        allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
        cli_exec(%w[index async_import CitiesIndex --service=faktory])
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").to have_enqueued_async_indexing_job("CitiesIndex", "city", "batch_id", {}).on(:faktory)
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").not_to have_enqueued_async_indexing_job.on(:sidekiq)
      end

      it "detects faktory as the default service name when not passed and is set in the configuration" do
        Esse.config.async_indexing.faktory
        allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
        cli_exec(%w[index async_import CitiesIndex])
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").to have_enqueued_async_indexing_job("CitiesIndex", "city", "batch_id", {}).on(:faktory)
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").not_to have_enqueued_async_indexing_job.on(:sidekiq)
      end

      it "enqueues the faktory job for the given index when passing --service=sidekiq" do
        allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
        cli_exec(%w[index async_import CitiesIndex --service=sidekiq])
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").to have_enqueued_async_indexing_job("CitiesIndex", "city", "batch_id", {}).on(:sidekiq)
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").not_to have_enqueued_async_indexing_job.on(:faktory)
      end

      it "detects sidekiq as the default service name when not passed and is set in the configuration" do
        Esse.config.async_indexing.sidekiq
        allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
        cli_exec(%w[index async_import CitiesIndex])
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").to have_enqueued_async_indexing_job("CitiesIndex", "city", "batch_id", {}).on(:sidekiq)
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").not_to have_enqueued_async_indexing_job.on(:faktory)
      end
    end

    context "when passing a index with multiple repositories that support async indexing", :async_indexing_job do
      before do
        collection_class = index_collection_class
        stub_esse_index(:geos) do
          plugin :async_indexing
          repository :country do
            collection collection_class
          end
          repository :city do
            collection collection_class
          end
        end
      end

      it "enqueues the faktory job for the given index when passing --service=faktory" do
        allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
        cli_exec(%w[index async_import GeosIndex --service=faktory])
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").to have_enqueued_async_indexing_job("GeosIndex", "country", "batch_id", {}).on(:faktory)
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").to have_enqueued_async_indexing_job("GeosIndex", "city", "batch_id", {}).on(:faktory)
      end

      it "enqueues the faktory job for the given index when passing --service=sidekiq" do
        allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
        cli_exec(%w[index async_import GeosIndex --service=sidekiq])
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").to have_enqueued_async_indexing_job("GeosIndex", "country", "batch_id", {}).on(:sidekiq)
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").to have_enqueued_async_indexing_job("GeosIndex", "city", "batch_id", {}).on(:sidekiq)
      end
    end

    context "when passing a index with a custom indexing job defined", :async_indexing_job do
      before do
        collection_class = index_collection_class
        stub_esse_index(:geos) do
          plugin :async_indexing
          repository :country do
            collection collection_class
            async_indexing_job(:import) do |repo, op, ids, **options|
              Thread.current[:custom_job] = [repo, op, ids, options]
            end
          end
        end
      end

      it "enqueues the custom job for the given index when passing --service=faktory" do
        allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
        cli_exec(%w[index async_import GeosIndex --service=faktory])
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").not_to have_enqueued_async_indexing_job
        expect(Thread.current[:custom_job]).to eq([GeosIndex::Country, :import, [1, 2, 3], {}])
      end

      it "enqueues the custom job for the given index when passing --service=sidekiq" do
        allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
        cli_exec(%w[index async_import GeosIndex --service=sidekiq])
        expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").not_to have_enqueued_async_indexing_job
        expect(Thread.current[:custom_job]).to eq([GeosIndex::Country, :import, [1, 2, 3], {}])
      end
    end
  end
end
# rubocop:enable RSpec/ExpectActual
# rubocop:enable RSpec/AnyInstance
