# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Worker do
  let(:worker) { described_class.new("DummyWorker") }

  describe "#options" do
    specify do
      expected_options = described_class.new("DummyWorker").options
      expect(expected_options).to eq({})
    end

    specify do
      expected_options = described_class.new("DummyWorker", retry: true).options
      expect(expected_options).to eq(retry: true)
    end
  end

  describe "#created_at", freeze_at: [2020, 7, 1, 22, 24, 40] do
    let(:now) { Time.now }

    specify do
      expect(worker.payload).to eq({})
      expect(worker.created_at(now)).to eq(worker)
      expect(worker.payload).to eq("created_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.created_at(Time.now)).to eq(worker)
      expect(worker.payload).to eq("created_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.created_at(Time.now.to_datetime.rfc3339(9))).to eq(worker)
      expect(worker.payload).to eq("created_at" => now.to_f)
    end
  end

  describe "#enqueued_at", freeze_at: [2020, 7, 1, 22, 24, 40] do
    let(:now) { Time.now }

    specify do
      expect(worker.payload).to eq({})
      expect(worker.enqueued_at(now)).to eq(worker)
      expect(worker.payload).to eq("enqueued_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.enqueued_at(Time.now)).to eq(worker)
      expect(worker.payload).to eq("enqueued_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.enqueued_at(Time.now.to_datetime.rfc3339(9))).to eq(worker)
      expect(worker.payload).to eq("enqueued_at" => now.to_f)
    end
  end

  describe "#with_args" do
    specify do
      expect(worker.payload).to eq({})
      expect(worker.with_args).to eq(worker)
      expect(worker.payload).to eq("args" => [])
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.with_args(1)).to eq(worker)
      expect(worker.payload).to eq("args" => [1])
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.with_args(1, foo: :bar)).to eq(worker)
      expect(worker.payload).to eq("args" => [1, {foo: :bar}])
    end
  end

  describe "#at", freeze_at: [2020, 7, 1, 22, 24, 40] do
    let(:now) { Time.now }

    specify do
      expect(worker.payload).to eq({})
      expect(worker.at(10)).to eq(worker)
      expect(worker.payload).to eq("at" => now.to_f + 10, "created_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.at(now + HOUR_IN_SECONDS)).to eq(worker)
      expect(worker.payload).to eq("at" => now.to_f + 3_600, "created_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.at((now + HOUR_IN_SECONDS).to_datetime.rfc3339(9))).to eq(worker)
      expect(worker.payload).to eq("at" => now.to_f + 3_600, "created_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.at(0)).to eq(worker)
      expect(worker.payload).to eq({})
      expect(worker.at(now - 1)).to eq(worker)
      expect(worker.payload).to eq({})
    end
  end

  describe "#in", freeze_at: [2020, 7, 1, 22, 24, 40] do
    let(:now) { Time.now }

    specify do
      expect(worker.payload).to eq({})
      expect(worker.in(10)).to eq(worker)
      expect(worker.payload).to eq("at" => now.to_f + 10, "created_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.in(now + HOUR_IN_SECONDS)).to eq(worker)
      expect(worker.payload).to eq("at" => now.to_f + 3_600, "created_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.in((now + HOUR_IN_SECONDS).to_datetime.rfc3339(9))).to eq(worker)
      expect(worker.payload).to eq("at" => now.to_f + 3_600, "created_at" => now.to_f)
    end

    specify do
      expect(worker.payload).to eq({})
      expect(worker.in(0)).to eq(worker)
      expect(worker.payload).to eq({})
      expect(worker.in(now - 1)).to eq(worker)
      expect(worker.payload).to eq({})
    end
  end

  describe "#push", freeze_at: [2020, 7, 1, 22, 24, 40] do
    let(:now) { Time.now }

    specify do
      expect(worker.payload).to eq({})
      worker.instance_variable_set(:@service, :invalid)
      expect { worker.push }.to raise_error(
        Esse::AsyncIndexing::Error, /Service :invalid is not implemented. Please use one of :sidekiq or :faktory/
      )
      expect(worker.payload).to eq({})
    end

    context "with faktory service" do
      specify do
        allow(Esse::AsyncIndexing).to receive(:jid).and_return("123xyz")
        allow(Esse::AsyncIndexing::Adapters::Faktory).to receive(:push).with(worker).and_return("ok")
        worker.instance_variable_set(:@service, :faktory)
        expect(worker.push).to eq("ok")
        expect(worker.payload).to eq("jid" => "123xyz", "created_at" => now.to_f)
      end

      specify do
        worker = described_class.new("DummyWorker", service: :faktory)
        allow(Esse::AsyncIndexing::Adapters::Faktory).to receive(:push).with(worker).and_return("ok")
        expect(worker.push).to eq("ok")
      end
    end

    context "with sidekiq service" do
      specify do
        allow(Esse::AsyncIndexing).to receive(:jid).and_return("123xyz")
        allow(Esse::AsyncIndexing::Adapters::Sidekiq).to receive(:push).with(worker).and_return("ok")
        worker.instance_variable_set(:@service, :sidekiq)
        expect(worker.push).to eq("ok")
        expect(worker.payload).to eq("jid" => "123xyz", "created_at" => now.to_f)
      end

      specify do
        worker = described_class.new("DummyWorker", service: :sidekiq)
        allow(Esse::AsyncIndexing::Adapters::Sidekiq).to receive(:push).with(worker).and_return("ok")
        expect(worker.push).to eq("ok")
      end
    end
  end

  describe ".coerce class method" do
    let(:options) { {queue: "custom"} }

    after do
      reset_config!
    end

    context "with :faktory" do
      let(:payload) { {"jid" => "123", "jobtype" => "DummyWorker", "args" => [1]} }

      before do
        Esse.config.async_indexing.faktory.workers = {
          "DummyWorker" => options
        }
      end

      specify do
        allow(Esse::AsyncIndexing::Adapters::Faktory).to receive(:coerce_to_worker).and_call_original
        expect(described_class.coerce(service: :faktory, payload: payload, **options)).to be_an_instance_of(described_class)
        expect(Esse::AsyncIndexing::Adapters::Faktory).to have_received(:coerce_to_worker).with(payload, **options)
      end
    end

    context "with :sidekiq" do
      let(:payload) { {"jid" => "123", "class" => "DummyWorker", "args" => [1]} }

      before do
        Esse.config.async_indexing.sidekiq.workers = {
          "DummyWorker" => options
        }
      end

      specify do
        allow(Esse::AsyncIndexing::Adapters::Sidekiq).to receive(:coerce_to_worker).and_call_original
        expect(described_class.coerce(service: :sidekiq, payload: payload, **options)).to be_an_instance_of(described_class)
        expect(Esse::AsyncIndexing::Adapters::Sidekiq).to have_received(:coerce_to_worker).with(payload, **options)
      end
    end

    context "with undefined service" do
      specify do
        expect { described_class.coerce(service: :invalid, payload: {}, **options) }.to raise_error(KeyError)
      end
    end
  end

  describe "#eql?" do
    context "with worker class name" do
      specify do
        worker = described_class.new("Foo")
        expect(worker).to eql(described_class.new("Foo"))
        expect(worker).not_to eql(described_class.new("Bar"))
      end
    end

    context "with job content" do
      specify do
        worker = described_class.new("Foo").with_args([1])
        expect(worker).to eql(described_class.new("Foo").with_args([1]))
        expect(worker).not_to eql(described_class.new("Foo").with_args([2]))
      end
    end

    context "with worker options" do
      specify do
        worker = described_class.new("Foo", queue: "foo")
        expect(worker).to eql(described_class.new("Foo", queue: "foo"))
        expect(worker).not_to eql(described_class.new("Foo", queue: "bar"))
      end
    end
  end
end
