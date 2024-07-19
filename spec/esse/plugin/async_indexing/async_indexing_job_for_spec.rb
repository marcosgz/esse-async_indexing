# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/ExpectActual
# rubocop:disable RSpec/AnyInstance
RSpec.describe Esse::Plugins::AsyncIndexing, "#async_indexing_job_for", :async_indexing_job do # rubocop:disable RSpec/SpecFilePathFormat
  before do
    Thread.current[:custom_job] = nil
  end

  context "when :import operation" do
    it "returns the async_indexing_job user-defined implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job(:import) { |service, repo, op, ids, **kwargs| Thread.current[:custom_job] = [service, repo, op, ids, kwargs] }
        end
      end

      expect(GeosIndex::State.async_indexing_job_for(:import)).to be_a(Proc)
      expect {
        GeosIndex::State.async_indexing_job_for(:import).call(:faktory, GeosIndex::State, :import, [1], {})
      }.to change { Thread.current[:custom_job] }.from(nil).to([:faktory, GeosIndex::State, :import, [1], {}])
      expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").not_to have_enqueued_async_indexing_job
    end

    it "returns the default async_indexing_job implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
      expect(GeosIndex::State.async_indexing_job_for(:import)).to be_a(Proc)

      GeosIndex::State.async_indexing_job_for(:import).call(:faktory, GeosIndex::State, :import, [1], {suffix: "foo"})
      expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").to have_enqueued_async_indexing_job("GeosIndex", "state", "batch_id", {suffix: "foo"})
    end

    it "does not enqueue the job if the ids are empty" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:import)).to be_a(Proc)
      GeosIndex::State.async_indexing_job_for(:import).call(:faktory, GeosIndex::State, :import, [], {suffix: "foo"})
      GeosIndex::State.async_indexing_job_for(:import).call(:faktory, GeosIndex::State, :import, nil, {suffix: "foo"})
      expect("Esse::AsyncIndexing::Jobs::ImportBatchIdJob").not_to have_enqueued_async_indexing_job
    end
  end

  context "when :index operation" do
    it "returns the async_indexing_job user-defined implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job(:index) { |service, repo, op, id, **kwargs| Thread.current[:custom_job] = [service, repo, op, id, kwargs] }
        end
      end

      expect(GeosIndex::State.async_indexing_job_for(:index)).to be_a(Proc)
      expect {
        GeosIndex::State.async_indexing_job_for(:index).call(:faktory, GeosIndex::State, :index, 1, {})
      }.to change { Thread.current[:custom_job] }.from(nil).to([:faktory, GeosIndex::State, :index, 1, {}])
      expect("Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob").not_to have_enqueued_async_indexing_job
    end

    it "returns the default async_indexing_job implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
      expect(GeosIndex::State.async_indexing_job_for(:index)).to be_a(Proc)
      GeosIndex::State.async_indexing_job_for(:index).call(:faktory, GeosIndex::State, :index, 1, {suffix: "foo"})

      expect("Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob").to have_enqueued_async_indexing_job("GeosIndex", "state", 1, {suffix: "foo"})
    end

    it "does not enqueue the job if the id is nil" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:index)).to be_a(Proc)
      GeosIndex::State.async_indexing_job_for(:index).call(:faktory, GeosIndex::State, :index, nil, {suffix: "foo"})
      expect("Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob").not_to have_enqueued_async_indexing_job
    end
  end

  context "when :update operation" do
    it "returns the async_indexing_job user-defined implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job(:update) { |service, repo, op, id, **kwargs| Thread.current[:custom_job] = [service, repo, op, id, kwargs] }
        end
      end

      expect(GeosIndex::State.async_indexing_job_for(:update)).to be_a(Proc)
      expect {
        GeosIndex::State.async_indexing_job_for(:update).call(:faktory, GeosIndex::State, :update, 1, {})
      }.to change { Thread.current[:custom_job] }.from(nil).to([:faktory, GeosIndex::State, :update, 1, {}])
      expect("Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob").not_to have_enqueued_async_indexing_job
    end

    it "returns the default async_indexing_job implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
      expect(GeosIndex::State.async_indexing_job_for(:update)).to be_a(Proc)
      GeosIndex::State.async_indexing_job_for(:update).call(:faktory, GeosIndex::State, :update, 1, {suffix: "foo"})
      expect("Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob").to have_enqueued_async_indexing_job("GeosIndex", "state", 1, {suffix: "foo"})
    end

    it "does not enqueue the job if the id is nil" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:update)).to be_a(Proc)
      GeosIndex::State.async_indexing_job_for(:update).call(:faktory, GeosIndex::State, :update, nil, {suffix: "foo"})
      expect("Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob").not_to have_enqueued_async_indexing_job
    end
  end

  context "when :delete operation" do
    it "returns the async_indexing_job user-defined implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job(:delete) { |service, repo, op, id, **kwargs| Thread.current[:custom_job] = [service, repo, op, id, kwargs] }
        end
      end

      expect(GeosIndex::State.async_indexing_job_for(:delete)).to be_a(Proc)
      expect {
        GeosIndex::State.async_indexing_job_for(:delete).call(:faktory, GeosIndex::State, :delete, 1, {})
      }.to change { Thread.current[:custom_job] }.from(nil).to([:faktory, GeosIndex::State, :delete, 1, {}])
      expect("Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob").not_to have_enqueued_async_indexing_job
    end

    it "returns the default async_indexing_job implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      allow_any_instance_of(Esse::RedisStorage::Queue).to receive(:enqueue).and_return("batch_id")
      expect(GeosIndex::State.async_indexing_job_for(:delete)).to be_a(Proc)
      GeosIndex::State.async_indexing_job_for(:delete).call(:faktory, GeosIndex::State, :delete, 1, {suffix: "foo"})
      expect("Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob").to have_enqueued_async_indexing_job("GeosIndex", "state", 1, {suffix: "foo"})
    end

    it "does not enqueue the job if the id is nil" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:delete)).to be_a(Proc)
      GeosIndex::State.async_indexing_job_for(:delete).call(:faktory, GeosIndex::State, :delete, nil, {suffix: "foo"})
      expect("Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob").not_to have_enqueued_async_indexing_job
    end
  end

  context "when passing an unknown operation" do
    it "raises an error" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect {
        GeosIndex::State.async_indexing_job_for(:unknown)
      }.to raise_error(ArgumentError, /unknown operation/)
    end
  end
end
# rubocop:enable RSpec/ExpectActual
# rubocop:enable RSpec/AnyInstance
