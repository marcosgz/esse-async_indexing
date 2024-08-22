# frozen_string_literal: true

require "spec_helper"
require "support/cli_helpers"
require "esse/cli"
require "esse/async_indexing/cli/async_update_lazy_attributes"

# rubocop:disable RSpec/ExpectActual
# rubocop:disable RSpec/AnyInstance
RSpec.describe "Esse::CLI::Index", type: :cli do
  describe "#async_update_lazy_attributes" do
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
      it "raises an error if given argument is not a valid index class" do
        expect {
          cli_exec(%w[index async_update_lazy_attributes Esse::Config])
        }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
      end

      it "raises an error if given argument is not defined" do
        expect {
          cli_exec(%w[index async_update_lazy_attributes NotDefinedIndexName])
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
          cli_exec(%w[index async_update_lazy_attributes CountiesIndex])
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
            lazy_document_attribute :total_events do |docs|
              docs.map { |doc| [doc.id, 10] }.to_h
            end
            lazy_document_attribute :total_venues do |docs|
              docs.map { |doc| [doc.id, 20] }.to_h
            end
          end
        end
      end

      it "enqueues the faktory job for the given index when passing --service=faktory" do
        cli_exec(%w[index async_update_lazy_attributes CitiesIndex --service=faktory])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_events", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_venues", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job.on(:sidekiq)
      end

      it "detects faktory as the default service name when not passed and is set in the configuration" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_update_lazy_attributes CitiesIndex])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_events", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_venues", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job.on(:sidekiq)
      end

      it "enqueues the faktory job for the given index when passing --service=sidekiq" do
        cli_exec(%w[index async_update_lazy_attributes CitiesIndex --service=sidekiq])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_events", [1, 2, 3], {}).on(:sidekiq)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_venues", [1, 2, 3], {}).on(:sidekiq)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job.on(:faktory)
      end

      it "detects sidekiq as the default service name when not passed and is set in the configuration" do
        Esse.config.async_indexing.sidekiq
        cli_exec(%w[index async_update_lazy_attributes CitiesIndex])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_events", [1, 2, 3], {}).on(:sidekiq)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_venues", [1, 2, 3], {}).on(:sidekiq)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job.on(:faktory)
      end

      it "enqueues only the specified lazy attribute job when the attribute is passed" do
        cli_exec(%w[index async_update_lazy_attributes CitiesIndex total_events --service=faktory])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_events", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job("CitiesIndex", "city", "total_venues", [1, 2, 3], {}).on(:faktory)
      end

      it "removes invalid given attributes" do
        cli_exec(%w[index async_update_lazy_attributes CitiesIndex total_venues invalid_attribute --service=faktory])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_venues", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job("CitiesIndex", "city", "invalid_attribute", [1, 2, 3], {}).on(:faktory)
      end

      it "does not enqueue when no valid lazy attributes are passed" do
        cli_exec(%w[index async_update_lazy_attributes CitiesIndex invalid_attribute --service=faktory])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job.on(:faktory)
      end

      it "allows --job-options with a Hash" do
        Esse.config.async_indexing.faktory
        cli_exec(%w[index async_update_lazy_attributes CitiesIndex --job-options=queue:bar])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_events", [1, 2, 3], {}).on(:faktory).queue("bar")
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("CitiesIndex", "city", "total_venues", [1, 2, 3], {}).on(:faktory).queue("bar")
      end
    end

    context "when passing a index with multiple repositories that support async indexing" do
      before do
        collection_class = index_collection_class
        stub_esse_index(:geos) do
          plugin :async_indexing
          repository :country do
            collection collection_class
            lazy_document_attribute :total_events do |docs|
              docs.map { |doc| [doc.id, 10] }.to_h
            end
          end
          repository :city do
            collection collection_class
            lazy_document_attribute :total_events do |docs|
              docs.map { |doc| [doc.id, 10] }.to_h
            end
          end
        end
      end

      it "enqueues the faktory job for the given index when passing --service=faktory" do
        cli_exec(%w[index async_update_lazy_attributes GeosIndex --service=faktory])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("GeosIndex", "country", "total_events", [1, 2, 3], {}).on(:faktory)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_events", [1, 2, 3], {}).on(:faktory)
      end

      it "enqueues the faktory job for the given index when passing --service=sidekiq" do
        cli_exec(%w[index async_update_lazy_attributes GeosIndex --service=sidekiq])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("GeosIndex", "country", "total_events", [1, 2, 3], {}).on(:sidekiq)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_events", [1, 2, 3], {}).on(:sidekiq)
      end
    end

    context "when passing a index with a custom indexing job defined" do
      before do
        collection_class = index_collection_class
        stub_esse_index(:geos) do
          plugin :async_indexing
          repository :country do
            collection collection_class
            lazy_document_attribute :total_events do |docs|
              docs.map { |doc| [doc.id, 10] }.to_h
            end
            async_indexing_job(:update_lazy_attribute) do |**options|
              Thread.current[:custom_job] = options
            end
          end
        end
      end

      it "enqueues the custom job for the given index when passing --service=faktory" do
        cli_exec(%w[index async_update_lazy_attributes GeosIndex --service=faktory])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job
        expect(Thread.current[:custom_job]).to eq(
          service: :faktory,
          repo: GeosIndex::Country,
          operation: :update_lazy_attribute,
          attribute: :total_events,
          ids: [1, 2, 3]
        )
      end

      it "enqueues the custom job for the given index when passing --service=sidekiq" do
        cli_exec(%w[index async_update_lazy_attributes GeosIndex --service=sidekiq])
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job
        expect(Thread.current[:custom_job]).to eq(
          service: :sidekiq,
          repo: GeosIndex::Country,
          operation: :update_lazy_attribute,
          attribute: :total_events,
          ids: [1, 2, 3]
        )
      end
    end
  end
end
# rubocop:enable RSpec/ExpectActual
# rubocop:enable RSpec/AnyInstance
