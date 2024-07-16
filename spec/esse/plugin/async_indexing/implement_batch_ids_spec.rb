# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::Plugins::AsyncIndexing, "#implement_batch_ids?" do
  it "returns false when the collection_proc is nil" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state, const: true
    end
    expect(GeosIndex::State.implement_batch_ids?).to be(false)
  end

  it "returns false when the collection_proc is not a class" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state do
        collection -> {}
      end
    end
    expect(GeosIndex::State.implement_batch_ids?).to be(false)
  end

  it "returns false when the collection_proc does not implement the each_batch_ids method" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state do
        collection Class.new(Esse::Collection)
      end
    end
    expect(GeosIndex::State.implement_batch_ids?).to be(false)
  end

  it "returns true when the collection_proc is a class and implements the each_batch_ids method" do
    collection_class = Class.new(Esse::Collection) do
      def each_batch_ids
        yield([1, 2, 3])
      end
    end
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state do
        collection collection_class
      end
    end
    expect(GeosIndex::State.implement_batch_ids?).to be(true)
  end
end
