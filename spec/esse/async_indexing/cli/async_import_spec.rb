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

    before do
      Esse.config.async_indexing.faktory
      Esse.config.async_indexing.sidekiq
    end

    after do
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
        }.to raise_error(Esse::CLI::InvalidOption, /The CountiesIndex index does not support async indexing. Make sure you have/)
      end
    end

    context "when passing a index with single repository that supports async indexing" do
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
        cli_exec(%w[index async_import CitiesIndex --service=faktory])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.not_to have_enqueued_background_job.on(:sidekiq)
      end

      it "detects faktory as the default service name when not passed and is set in the configuration" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.not_to have_enqueued_background_job.on(:sidekiq)
      end

      it "enqueues the faktory job for the given index when passing --service=sidekiq" do
        cli_exec(%w[index async_import CitiesIndex --service=sidekiq])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], {}).on(:sidekiq)
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.not_to have_enqueued_background_job.on(:faktory)
      end

      it "detects sidekiq as the default service name when not passed and is set in the configuration" do
        Esse.config.async_indexing.sidekiq
        cli_exec(%w[index async_import CitiesIndex])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], {}).on(:sidekiq)
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.not_to have_enqueued_background_job.on(:faktory)
      end

      it "allows --update-lazy-attributes as a single value" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --update-lazy-attributes=foo])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "update_lazy_attributes" => ["foo"]).on(:faktory)
      end

      it "allows --update-lazy-attributes as multiple comma separated values" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --update-lazy-attributes=foo,bar])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "update_lazy_attributes" => %w[foo bar]).on(:faktory)
      end

      it "allows --eager-load-lazy-attributes as true" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --eager-load-lazy-attributes=true])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "eager_load_lazy_attributes" => true).on(:faktory)
      end

      it "allows --no-enqueue-lazy-attributes" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --no-enqueue-lazy-attributes])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "enqueue_lazy_attributes" => false).on(:faktory)
      end

      it "allows --eager-load-lazy-attributes as false" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --eager-load-lazy-attributes=false])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], {}).on(:faktory)
      end

      it "allows --eager-load-lazy-attributes as a single value" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --eager-load-lazy-attributes=foo])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "eager_load_lazy_attributes" => ["foo"]).on(:faktory)
      end

      it "allows --eager-load-lazy-attributes as multiple comma separated values" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --eager-load-lazy-attributes=foo,bar])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "eager_load_lazy_attributes" => %w[foo bar]).on(:faktory)
      end

      it "allows --eager-load-lazy-attributes and --update-lazy-attributes together" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --eager-load-lazy-attributes=foo,bar --update-lazy-attributes=baz])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "eager_load_lazy_attributes" => %w[foo bar], "update_lazy_attributes" => ["baz"]).on(:faktory)
      end

      it "allows --preload-lazy-attributes as true" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --preload-lazy-attributes=true])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "preload_lazy_attributes" => true).on(:faktory)
      end

      it "allows --preload-lazy-attributes as false" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --preload-lazy-attributes=false])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], {}).on(:faktory)
      end

      it "allows --preload-lazy-attributes as a single value" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --preload-lazy-attributes=foo])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "preload_lazy_attributes" => ["foo"]).on(:faktory)
      end

      it "allows --preload-lazy-attributes as multiple comma separated values" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --preload-lazy-attributes=foo,bar])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], "preload_lazy_attributes" => %w[foo bar]).on(:faktory)
      end

      it "allows --job-options with a Hash" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_import CitiesIndex --job-options=queue:bar])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("CitiesIndex", "city", [1, 2, 3], {}).on(:faktory).queue("bar")
      end
    end

    context "when passing a index with multiple repositories that support async indexing" do
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
        cli_exec(%w[index async_import GeosIndex --service=faktory])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("GeosIndex", "country", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("GeosIndex", "city", [1, 2, 3], {}).on(:faktory)
      end

      it "enqueues the faktory job for the given index when passing --service=sidekiq" do
        cli_exec(%w[index async_import GeosIndex --service=sidekiq])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("GeosIndex", "country", [1, 2, 3], {}).on(:sidekiq)
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("GeosIndex", "city", [1, 2, 3], {}).on(:sidekiq)
      end
    end

    context "when passing a index with a custom indexing job defined" do
      before do
        collection_class = index_collection_class
        stub_esse_index(:geos) do
          plugin :async_indexing
          repository :country do
            collection collection_class
            async_indexing_job(:import) do |**options|
              Thread.current[:custom_job] = options
            end
          end
        end
      end

      it "enqueues the custom job for the given index when passing --service=faktory" do
        cli_exec(%w[index async_import GeosIndex --service=faktory --eager-load-lazy-attributes=true])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.not_to have_enqueued_background_job
        expect(Thread.current[:custom_job]).to eq(
          service: :faktory,
          repo: GeosIndex::Country,
          operation: :import,
          ids: [1, 2, 3],
          eager_load_lazy_attributes: true
        )
      end

      it "enqueues the custom job for the given index when passing --service=sidekiq" do
        cli_exec(%w[index async_import GeosIndex --service=sidekiq])
        expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.not_to have_enqueued_background_job
        expect(Thread.current[:custom_job]).to eq(
          service: :sidekiq,
          repo: GeosIndex::Country,
          operation: :import,
          ids: [1, 2, 3]
        )
      end
    end
  end
end
# rubocop:enable RSpec/ExpectActual
# rubocop:enable RSpec/AnyInstance
