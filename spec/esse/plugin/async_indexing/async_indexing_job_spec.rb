# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::Plugins::AsyncIndexing, "#async_indexing_job" do # rubocop:disable RSpec/SpecFilePathFormat
  it "initializes the @async_indexing_tasks instance variable" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state, const: true
    end
    expect { GeosIndex::State.async_indexing_job(:import) { |**| } }.to change { GeosIndex::State.instance_variable_get(:@async_indexing_tasks) }.from(nil).to(be_a(Esse::AsyncIndexing::Tasks))
  end

  it "does not set the @async_indexing_tasks instance when validation fails" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state, const: true
    end
    expect { GeosIndex::State.async_indexing_job(:invalid) }.to raise_error(ArgumentError)
    expect(GeosIndex::State.instance_variable_get(:@async_indexing_tasks)).to be(nil)
  end

  it "sets the default async indexing job caller for a single operation" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state, const: true
    end

    expect(GeosIndex::State.async_indexing_job?(:import)).to be(false)
    GeosIndex::State.async_indexing_job(:import) { |**| }
    expect(GeosIndex::State.async_indexing_job?(:import)).to be(true)
    expect(GeosIndex::State.async_indexing_job?(:index)).to be(false)
  end

  it "sets the default async indexing job caller for the all operations" do
    stub_esse_index(:geos) do
      plugin :async_indexing
      repository :state, const: true do
        async_indexing_job { |service, repo, op, ids, **kwargs| }
      end
    end

    expect(GeosIndex::State.async_indexing_job?(:import)).to be(true)
    expect(GeosIndex::State.async_indexing_job?(:index)).to be(true)
    expect(GeosIndex::State.async_indexing_job?(:update)).to be(true)
    expect(GeosIndex::State.async_indexing_job?(:delete)).to be(true)
    expect(GeosIndex::State.async_indexing_job?(:update_lazy_attribute)).to be(true)
  end
end
