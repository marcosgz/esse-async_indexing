# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/ExpectActual
# rubocop:disable RSpec/AnyInstance
RSpec.describe Esse::Plugins::AsyncIndexing, "#async_indexing_job_for" do # rubocop:disable RSpec/SpecFilePathFormat
  before do
    Thread.current[:custom_job] = nil
    Esse.config.async_indexing.faktory # Setup faktory jobs
  end

  after do
    reset_config!
  end

  context "when :import operation" do
    it "returns the async_indexing_job user-defined implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job(:import) { |**kwargs| Thread.current[:custom_job] = [kwargs] }
        end
      end

      expect(GeosIndex::State.async_indexing_job_for(:import)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :import, id: 1, suffix: "foo"}
      expect {
        GeosIndex::State.async_indexing_job_for(:import).call(**kwargs)
      }.to change { Thread.current[:custom_job] }.from(nil).to([kwargs])
      expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.not_to have_enqueued_background_job
    end

    it "returns the default async_indexing_job implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:import)).to be_a(Proc)

      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :import, ids: 1, suffix: "foo"}
      GeosIndex::State.async_indexing_job_for(:import).call(**kwargs)
      expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.to have_enqueued_background_job("GeosIndex", "state", [1], {"suffix" => "foo"})
    end

    it "does not enqueue the job if the ids are empty" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:import)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :import, suffix: "foo"}
      GeosIndex::State.async_indexing_job_for(:import).call(**kwargs, ids: [])
      GeosIndex::State.async_indexing_job_for(:import).call(**kwargs, ids: nil)
      expect { "Esse::AsyncIndexing::Jobs::ImportIdsJob" }.not_to have_enqueued_background_job
    end
  end

  context "when :index operation" do
    it "returns the async_indexing_job user-defined implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job(:index) { |**kwargs| (Thread.current[:custom_job] ||= []) << kwargs }
        end
      end

      expect(GeosIndex::State.async_indexing_job_for(:index)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :index, id: 1, suffix: "foo"}
      expect {
        GeosIndex::State.async_indexing_job_for(:index).call(**kwargs)
      }.to change { Thread.current[:custom_job] }.from(nil).to([kwargs])
      expect { "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob" }.not_to have_enqueued_background_job
    end

    it "returns the default async_indexing_job implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :index, id: 1, suffix: "foo"}
      expect(GeosIndex::State.async_indexing_job_for(:index)).to be_a(Proc)
      GeosIndex::State.async_indexing_job_for(:index).call(**kwargs)

      expect { "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob" }.to have_enqueued_background_job("GeosIndex", "state", 1, {"suffix" => "foo"})
    end

    it "does not enqueue the job if the id is nil" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:index)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :index, id: nil, suffix: "foo"}
      GeosIndex::State.async_indexing_job_for(:index).call(**kwargs)
      expect { "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob" }.not_to have_enqueued_background_job
    end
  end

  context "when :update operation" do
    it "returns the async_indexing_job user-defined implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job(:update) { |**kwargs| Thread.current[:custom_job] = [kwargs] }
        end
      end

      expect(GeosIndex::State.async_indexing_job_for(:update)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :update, id: 1, suffix: "foo"}
      expect {
        GeosIndex::State.async_indexing_job_for(:update).call(**kwargs)
      }.to change { Thread.current[:custom_job] }.from(nil).to([kwargs])
      expect { "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob" }.not_to have_enqueued_background_job
    end

    it "returns the default async_indexing_job implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:update)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :update, id: 1, suffix: "foo"}
      GeosIndex::State.async_indexing_job_for(:update).call(**kwargs)
      expect { "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob" }.to have_enqueued_background_job("GeosIndex", "state", 1, {"suffix" => "foo"})
    end

    it "does not enqueue the job if the id is nil" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:update)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :update, id: nil, suffix: "foo"}
      GeosIndex::State.async_indexing_job_for(:update).call(**kwargs)
      expect { "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob" }.not_to have_enqueued_background_job
    end
  end

  context "when :delete operation" do
    it "returns the async_indexing_job user-defined implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true do
          async_indexing_job(:delete) { |**kwargs| (Thread.current[:custom_job] ||= []) << kwargs }
        end
      end

      expect(GeosIndex::State.async_indexing_job_for(:delete)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :delete, id: 1, suffix: "foo"}
      expect {
        GeosIndex::State.async_indexing_job_for(:delete).call(**kwargs)
      }.to change { Thread.current[:custom_job] }.from(nil).to([kwargs])
      expect { "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob" }.not_to have_enqueued_background_job
    end

    it "returns the default async_indexing_job implementation" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:delete)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :delete, id: 1, suffix: "foo"}
      GeosIndex::State.async_indexing_job_for(:delete).call(**kwargs)
      expect { "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob" }.to have_enqueued_background_job("GeosIndex", "state", 1, {"suffix" => "foo"})
    end

    it "does not enqueue the job if the id is nil" do
      stub_esse_index(:geos) do
        plugin :async_indexing
        repository :state, const: true
      end

      expect(GeosIndex::State.async_indexing_job_for(:delete)).to be_a(Proc)
      kwargs = {service: :faktory, repo: GeosIndex::State, operation: :delete, id: nil, suffix: "foo"}
      GeosIndex::State.async_indexing_job_for(:delete).call(**kwargs)
      expect { "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob" }.not_to have_enqueued_background_job
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
