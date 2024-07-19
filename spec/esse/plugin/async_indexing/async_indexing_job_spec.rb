# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::Plugins::AsyncIndexing, "#async_indexing_job" do # rubocop:disable RSpec/SpecFilePathFormat
  it "sets custom async indexing job caller for the all operations" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state, const: true do
        async_indexing_job { |service, repo, op, ids, **kwargs| }
      end
    end
    expect(GeosIndex::State.async_indexing_jobs.keys).to match_array(%i[import index update delete])
    expect(GeosIndex::State.async_indexing_jobs).to be_frozen
  end

  it "sets custom async indexing job caller for the given operations" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state, const: true do
        async_indexing_job(:import) { |service, repo, op, ids, **kwargs| }
      end
    end
    expect(GeosIndex::State.async_indexing_jobs.keys).to match_array(%i[import])
    expect(GeosIndex::State.async_indexing_jobs[:import]).to be_a(Proc)
  end

  it "sets multiple custom async indexing job caller for the given operations" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state, const: true do
        async_indexing_job(:import) { |service, repo, op, ids, **kwargs| }
        async_indexing_job(:index) { |service, repo, op, id, **kwargs| }
      end
    end
    expect(GeosIndex::State.async_indexing_jobs.keys).to match_array(%i[import index])
    expect(GeosIndex::State.async_indexing_jobs[:import]).to be_a(Proc)
    expect(GeosIndex::State.async_indexing_jobs[:index]).to be_a(Proc)
  end

  it "raises an error when the async_indexing_job block is not given" do
    expect {
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job
        end
      end
    }.to raise_error(ArgumentError, /The block of async_indexing_job must be a callable object/)
    expect(GeosIndex::State.async_indexing_jobs).to be_frozen
  end

  it "raises an error when the async_indexing_job block parameters does not match the expected" do
    expect {
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job { |repo, **kwargs| }
        end
      end
    }.to raise_error(ArgumentError, /block of async_indexing_job must have the following signature/)
  end

  it "raises an error when the async_indexing_job block is keywork arguments only" do
    expect {
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job { |**kwargs| }
        end
      end
    }.to raise_error(ArgumentError, /block of async_indexing_job must have the following signature/)
  end
end
