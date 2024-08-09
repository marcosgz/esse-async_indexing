# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Esse::AsyncIndexing::Workers::Sidekiq" do
  describe "Esse::AsyncIndexing::Workers#for" do
    context "with default settings" do
      let(:worker) do
        Class.new do
          extend Esse::AsyncIndexing::Workers.for(:sidekiq)

          def self.name
            "DummyWorker"
          end
        end
      end

      specify do
        expect(worker).to respond_to(:perform_async)
        expect(worker).to respond_to(:perform_in)
        expect(worker).to respond_to(:perform_at)
      end

      specify do
        expect(worker.service_worker_options).to eq(
          queue: "default",
          retry: 15
        )
      end
    end

    context "with global Sidekiq < 7 available" do
      let(:worker_module) { Module.new }
      let(:worker) do
        Class.new do
          extend Esse::AsyncIndexing::Workers.for(:sidekiq)

          def self.name
            "DummyWorker"
          end
        end
      end

      before do
        Object.const_set(:Sidekiq, Class.new do
          def self.default_worker_options
            {
              "queue" => "dummy",
              "retry" => 0
            }
          end
        end)
        Object.const_get(:Sidekiq).const_set(:Worker, worker_module)
      end

      after do
        Object.send(:remove_const, :Sidekiq) # rubocop:disable RSpec/RemoveConst
        reset_config!
      end

      specify do
        expect(worker).to respond_to(:perform_async)
        expect(worker).to respond_to(:perform_in)
        expect(worker).to respond_to(:perform_at)
      end

      specify do
        expect(worker.service_worker_options).to eq(
          queue: "dummy",
          retry: 0
        )
      end
    end

    context "with global Sidekiq >= 7 available" do
      let(:worker_module) { Module.new }
      let(:worker) do
        Class.new do
          extend Esse::AsyncIndexing::Workers.for(:sidekiq)

          def self.name
            "DummyWorker"
          end
        end
      end

      before do
        Object.const_set(:Sidekiq, Class.new do
          def self.default_job_options
            {
              "queue" => "dummy",
              "retry" => 0
            }
          end
        end)
        Object.const_get(:Sidekiq).const_set(:Worker, worker_module)
      end

      after do
        Object.send(:remove_const, :Sidekiq) # rubocop:disable RSpec/RemoveConst
        reset_config!
      end

      specify do
        expect(worker).to respond_to(:perform_async)
        expect(worker).to respond_to(:perform_in)
        expect(worker).to respond_to(:perform_at)
      end

      specify do
        expect(worker.service_worker_options).to eq(
          queue: "dummy",
          retry: 0
        )
      end

      specify do
        expect(worker.included_modules).to include(worker_module)
      end

      it "does not overwrite the :retry from configurations" do
        Esse.config.async_indexing.sidekiq.workers[worker.name] = {
          queue: "config"
        }
        expect(worker.service_worker_options).to eq(
          queue: "config",
          retry: 0
        )
      end

      it "does not overwrite the :queue from configurations" do
        Esse.config.async_indexing.sidekiq.workers[worker.name] = {
          retry: 10
        }
        expect(worker.service_worker_options).to eq(
          queue: "dummy",
          retry: 10
        )
      end
    end
  end
end
