# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing do
  it "has a version number" do
    expect(Esse::AsyncIndexing::VERSION).not_to be_nil
  end

  describe ".async_indexing_repo?" do
    it "returns false when the given value is not a Esse::Repository" do
      expect(described_class.async_indexing_repo?(nil)).to be(false)
      expect(described_class.async_indexing_repo?(Object)).to be(false)
      expect(described_class.async_indexing_repo?(Esse::Index)).to be(false)
    end

    it "returns false when the given repo does not have the :async_indexing plugin" do
      stub_esse_index(:geos) do
        repository :state, const: true
      end
      expect(described_class.async_indexing_repo?(GeosIndex::State)).to be(false)
    end

    it "returns false when the given repo with the :async_indexing plugin does not have a collection" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end
      expect(described_class.async_indexing_repo?(GeosIndex::State)).to be(false)
    end

    it "returns false when the given repo with the :async_indexing plugin have a collection but it is not a Esse::Collection" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          collection {}
        end
      end
      expect(described_class.async_indexing_repo?(GeosIndex::State)).to be(false)
    end

    it "returns false when the given repo with the :async_indexing plugin have a collection that does not implement the each_batch_ids method" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          collection Class.new(Esse::Collection)
        end
      end
      expect(described_class.async_indexing_repo?(GeosIndex::State)).to be(false)
    end

    it "returns true when the given repo with the :async_indexing plugin have a collection that implements the each_batch_ids method" do
      collection_class = Class.new(Esse::Collection) do
        def each_batch_ids
          yield([1, 2, 3])
        end
      end
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :county, const: true do
          collection(collection_class)
        end
      end
      expect(described_class.async_indexing_repo?(GeosIndex::County)).to be(true)
    end
  end

  describe ".service_name" do
    it "raises an error when no service is configured" do
      expect { described_class.service_name }.to raise_error(ArgumentError, "There are no async indexing services configured. Please configure at least one service or pass the service name as an argument.")
    end

    it "returns the first service when no identifier is given" do
      Esse.config.async_indexing.sidekiq
      expect(described_class.service_name).to eq(:sidekiq)
      reset_config!
    end

    it "returns the given service when it is valid" do
      expect(described_class.service_name(:faktory)).to eq(:faktory)
    end

    it "works with string identifiers" do
      expect(described_class.service_name("faktory")).to eq(:faktory)
    end

    it "raises an error when the given service is invalid" do
      expect { described_class.service_name(:invalid) }.to raise_error(ArgumentError, "Invalid service: :invalid, valid services are: sidekiq, faktory")
    end
  end
end
