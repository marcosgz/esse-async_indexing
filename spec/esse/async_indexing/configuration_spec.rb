# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Configuration do
  describe ".faktory" do
    it "returns the faktory config" do
      config = described_class.new
      expect(config.faktory).to be_a(BackgroundJob::Configuration::Faktory)
    end

    it "yields the faktory config" do
      config = described_class.new
      expect { |b| config.faktory(&b) }.to yield_with_args(BackgroundJob::Configuration::Faktory)
    end
  end

  describe ".sidekiq" do
    it "returns the sidekiq config" do
      config = described_class.new
      expect(config.sidekiq).to be_a(BackgroundJob::Configuration::Sidekiq)
    end

    it "yields the sidekiq config" do
      config = described_class.new
      expect { |b| config.sidekiq(&b) }.to yield_with_args(BackgroundJob::Configuration::Sidekiq)
    end
  end

  describe ".config_for" do
    it "returns the config for the given service" do
      config = described_class.new
      expect(config.config_for(:faktory)).to be_an_instance_of(BackgroundJob::Configuration::Faktory)
      expect(config.config_for(:sidekiq)).to be_an_instance_of(BackgroundJob::Configuration::Sidekiq)
    end

    it "raises an error for unknown services" do
      config = described_class.new
      expect { config.config_for(:unknown) }.to raise_error(ArgumentError, "Unknown service: unknown")
    end
  end

  describe ".reset!" do
    it "resets the config" do
      config = described_class.new
      config.faktory { |c| c.jobs["MyJob"] = {} }
      config.sidekiq { |c| c.jobs["MyJob"] = {} }
      config.reset!
      expect(config.instance_variable_get(:@faktory)).to be_nil
      expect(config.instance_variable_get(:@sidekiq)).to be_nil
    end
  end
end
