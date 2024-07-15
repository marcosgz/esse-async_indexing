# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Esse::AsyncIndexing::Workers::Faktory" do
  describe "Esse::AsyncIndexing::Workers#for" do
    context "with default settings" do
      let(:worker) do
        Class.new do
          extend Esse::AsyncIndexing::Workers.for(:faktory)

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
          retry: 25
        )
      end

      specify do
        expect(worker.bg_worker_options).to eq({
          service: :faktory
        })
      end
    end

    context "with global Faktory available" do
      let(:job_module) { Module.new }
      let(:worker) do
        Class.new do
          extend Esse::AsyncIndexing::Workers.for(:faktory)

          def self.name
            "DummyWorker"
          end
        end
      end

      before do
        stub_const("Faktory", Class.new do
          def self.default_job_options
            {
              "queue" => "dummy",
              "retry" => 0
            }
          end
        end)
        stub_const("Faktory::Job", job_module)
      end

      after do
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
        expect(worker.bg_worker_options).to eq({
          service: :faktory
        })
      end

      it "does not overwrite the :retry from configurations" do
        Esse.config.async_indexing.faktory.workers[worker.name] = {
          queue: "config"
        }
        expect(worker.service_worker_options).to eq(
          queue: "config",
          retry: 0
        )
      end

      it "does not overwrite the :queue from configurations" do
        Esse.config.async_indexing.faktory.workers[worker.name] = {
          retry: 10
        }
        expect(worker.service_worker_options).to eq(
          queue: "dummy",
          retry: 10
        )
      end
    end

    context "with custom settings" do
      let(:worker_one) do
        Class.new do
          extend Esse::AsyncIndexing::Workers.for(:faktory, queue: "one", retry: 1)

          def self.name
            "DummyWorkerOne"
          end
        end
      end

      let(:worker_two) do
        Class.new do
          extend Esse::AsyncIndexing::Workers.for(:faktory, queue: "two", retry: 2)

          def self.name
            "DummyWorkerTwo"
          end
        end
      end

      after do
        reset_config!
      end

      specify do
        expect(worker_one).to respond_to(:perform_async)
        expect(worker_two).to respond_to(:perform_async)
        expect(worker_one).to respond_to(:perform_in)
        expect(worker_two).to respond_to(:perform_in)
        expect(worker_one).to respond_to(:perform_at)
        expect(worker_one).to respond_to(:perform_at)
      end

      specify do
        expect(worker_one.bg_worker_options).to eq({
          queue: "one",
          retry: 1,
          service: :faktory
        })
        expect(worker_two.bg_worker_options).to eq({
          queue: "two",
          retry: 2,
          service: :faktory
        })
      end
    end
  end
end
