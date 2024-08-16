# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::Plugins::AsyncIndexing, "#batch_ids" do # rubocop:disable RSpec/SpecFilePathFormat
  it "raises an error when the collection_proc does not implement the each_batch_ids method" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state do
        collection Class.new(Esse::Collection)
      end
    end
    expect { GeosIndex::State.batch_ids }.to raise_error(NotImplementedError)
  end

  context "when the collection_proc implements the each_batch_ids method" do
    let(:collection_class) do
      Class.new(Esse::Collection) do
        def each_batch_ids
          yield([1, 2, 3])
        end
      end
    end

    before do
      col_class = collection_class
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state do
          collection col_class
        end
      end
    end

    it "returns an enumerator" do
      expect(GeosIndex::State.batch_ids).to be_an(Enumerator)
    end

    it "yields the batch ids by using enumerator method" do
      expect { |block| GeosIndex::State.batch_ids.each(&block) }.to yield_successive_args([1, 2, 3])
    end

    it "yields the batch ids" do
      expect { |block| GeosIndex::State.batch_ids(&block) }.to yield_successive_args([1, 2, 3])
    end
  end
end
