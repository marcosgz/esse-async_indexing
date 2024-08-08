# frozen_string_literal: true

require "spec_helper"
require "faktory"

RSpec.describe Esse::AsyncIndexing::Adapters::Faktory, freeze_at: [2020, 7, 2, 12, 30, 50] do
  let(:worker_class) { "DummyFaktoryWorker" }
  let(:worker_args) { ["User", 1] }
  let(:worker_opts) { {} }
  let(:worker_job_id) { "123xyz" }
  let(:worker) do
    Esse::AsyncIndexing::Worker
      .new(worker_class, **worker_opts)
      .with_job_jid(worker_job_id)
      .with_args(*worker_args)
  end
  let(:model) { described_class.new(worker) }

  before do
    Esse.config.async_indexing.faktory.workers = {"DummyWorker" => {}}
  end

  after do
    reset_config!
  end

  describe ".push class method" do
    specify do
      allow(described_class).to receive(:new).with(worker).and_return(instance_double(described_class, push: "ok"))
      expect(described_class.push(worker)).to eq("ok")
    end
  end

  describe ".push instance method", freeze_at: [2020, 7, 2, 12, 30, 50] do
    subject(:push!) { model.push }

    before do
      Esse.config.async_indexing.faktory.workers = {"DummyFaktoryWorker" => {}}
      Esse::AsyncIndexing::Testing.disable! # Ensure we are not in testing mode to actually push the job

      require "faktory/testing"
      Faktory::Testing.fake!
    end

    after do
      reset_config!

      Faktory::Queues.clear_all
      Faktory::Testing.disable!
    end

    let(:now) { Time.now.to_f }

    context "with a standard job" do
      it "adds a valid job hash to faktory" do
        result = push!
        expect(result).to eq(
          "args" => worker_args,
          "jobtype" => worker_class,
          "jid" => worker_job_id,
          "created_at" => Time.now.to_datetime.rfc3339(9),
          "enqueued_at" => Time.now.to_datetime.rfc3339(9),
          "queue" => "default",
          "retry" => 25
        )
        expect(Faktory::Queues["default"].size).to eq(1)
      end
    end

    context "with custom reserve_for" do
      let(:worker_opts) { {reserve_for: 10} }

      it "adds a valid job hash to faktory" do
        result = push!
        expect(result).to eq(
          "args" => worker_args,
          "jobtype" => worker_class,
          "jid" => worker_job_id,
          "created_at" => Time.now.to_datetime.rfc3339(9),
          "enqueued_at" => Time.now.to_datetime.rfc3339(9),
          "queue" => "default",
          "retry" => 25,
          "reserve_for" => 10
        )
        expect(Faktory::Queues["default"].size).to eq(1)
      end
    end

    context "with a scheduled job" do
      let(:worker_opts) { {queue: "mailer"} }

      before do
        worker.at(Time.now + HOUR_IN_SECONDS)
      end

      it "adds a valid job hash to faktory" do
        result = push!
        expect(result).to eq(
          "args" => worker_args,
          "jobtype" => worker_class,
          "jid" => worker_job_id,
          "at" => (Time.now + HOUR_IN_SECONDS).to_datetime.rfc3339(9),
          "created_at" => Time.now.to_datetime.rfc3339(9),
          "enqueued_at" => Time.now.to_datetime.rfc3339(9),
          "queue" => "mailer",
          "retry" => 25
        )
        expect(Faktory::Queues["default"].size).to eq(0)
        expect(Faktory::Queues["mailer"].size).to eq(1)
      end
    end
  end

  describe ".coerce_to_worker class method", freeze_at: [2020, 7, 2, 12, 30, 50] do
    before do
      Esse.config.async_indexing.faktory.workers = {
        "DummyFaktoryWorker" => {},
        "OtherWorker" => {}
      }
    end

    specify do
      expect { described_class.coerce_to_worker(nil) }.to raise_error(Esse::AsyncIndexing::Error, "invalid payload")
      expect { described_class.coerce_to_worker("test") }.to raise_error(Esse::AsyncIndexing::Error, "invalid payload")
      expect { described_class.coerce_to_worker({}) }.to raise_error(Esse::AsyncIndexing::Error, "invalid payload")
    end

    specify do
      expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker")
      not_expected = Esse::AsyncIndexing::Worker.new("OtherWorker")
      actual = described_class.coerce_to_worker(
        {
          "jobtype" => "DummyFaktoryWorker"
        }
      )
      expect(actual).to eq(expected)
      expect(actual).not_to eq(not_expected)
    end

    specify do
      expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker", retry: false)
      not_expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker", retry: true)
      actual = described_class.coerce_to_worker(
        {
          "jobtype" => "DummyFaktoryWorker",
          "retry" => false
        }
      )
      expect(actual).to eq(expected)
      expect(actual).not_to eq(not_expected)
    end

    specify do
      expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker", queue: "foo")
      not_expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker", queue: "bar")
      actual = described_class.coerce_to_worker(
        {
          "jobtype" => "DummyFaktoryWorker",
          "queue" => "foo"
        }
      )
      expect(actual).to eq(expected)
      expect(actual).not_to eq(not_expected)
    end

    specify do
      expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").with_args(1)
      not_expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").with_args([1, 2])
      actual = described_class.coerce_to_worker(
        {
          "jobtype" => "DummyFaktoryWorker",
          "args" => [1]
        }
      )
      expect(actual).to eq(expected)
      expect(actual).not_to eq(not_expected)
    end

    specify do
      expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").with_job_jid("123")
      not_expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").with_job_jid("456")
      actual = described_class.coerce_to_worker(
        {
          "jobtype" => "DummyFaktoryWorker",
          "jid" => "123"
        }
      )
      expect(actual).to eq(expected)
      expect(actual).not_to eq(not_expected)
    end

    specify do
      expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").created_at((Time.now - (MINUTE_IN_SECONDS * 10)).to_f)
      not_expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").created_at((Time.now - (MINUTE_IN_SECONDS * 11)).to_f)
      actual = described_class.coerce_to_worker(
        {
          "jobtype" => "DummyFaktoryWorker",
          "created_at" => (Time.now - (MINUTE_IN_SECONDS * 10)).to_f
        }
      )
      expect(actual).to eq(expected)
      expect(actual).not_to eq(not_expected)
    end

    specify do
      expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").enqueued_at((Time.now - (MINUTE_IN_SECONDS * 10)).to_f)
      not_expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").enqueued_at((Time.now - (MINUTE_IN_SECONDS * 11)).to_f)
      actual = described_class.coerce_to_worker(
        {
          "jobtype" => "DummyFaktoryWorker",
          "enqueued_at" => (Time.now - (MINUTE_IN_SECONDS * 10)).to_f
        }
      )
      expect(actual).to eq(expected)
      expect(actual).not_to eq(not_expected)
    end

    specify do
      expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").at(Time.now + (MINUTE_IN_SECONDS * 10))
      not_expected = Esse::AsyncIndexing::Worker.new("DummyFaktoryWorker").at(Time.now + (MINUTE_IN_SECONDS * 11))
      actual = described_class.coerce_to_worker(
        {
          "jobtype" => "DummyFaktoryWorker",
          "at" => (Time.now + (MINUTE_IN_SECONDS * 10)).to_datetime.rfc3339(9),
          "created_at" => (Time.now + (MINUTE_IN_SECONDS * 10)).to_datetime.rfc3339(9)
        }
      )
      expect(actual).to eq(expected)
      expect(actual).not_to eq(not_expected)
    end

    specify do
      expected = Esse::AsyncIndexing::Worker
        .new("DummyFaktoryWorker", queue: "other", retry: true)
        .with_args(123)
        .with_job_jid("16c4c1ee56d858d1a5d0cacb")
        .created_at(Time.now.to_f)
        .enqueued_at(Time.now.to_f)

      actual = described_class.coerce_to_worker(
        {
          "jobtype" => "DummyFaktoryWorker",
          "args" => [123],
          "retry" => true,
          "queue" => "other",
          "jid" => "16c4c1ee56d858d1a5d0cacb",
          "created_at" => Time.now.to_datetime.rfc3339(9),
          "enqueued_at" => Time.now.to_datetime.rfc3339(9)
        }
      )
      expect(actual).to eq(expected)
    end
  end
end
