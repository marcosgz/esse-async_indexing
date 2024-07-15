# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Configuration do
  describe "#faktory" do
    it "returns an instance of Esse::AsyncIndexing::Configuration::Faktory" do
      expect(described_class.new.faktory).to be_a(Esse::AsyncIndexing::Configuration::Faktory)
    end

    it "yields the configuration" do
      described_class.new.faktory do |config|
        expect(config).to be_a(Esse::AsyncIndexing::Configuration::Faktory)
      end
    end
  end

  describe "#sidekiq" do
    it "returns an instance of Esse::AsyncIndexing::Configuration::Sidekiq" do
      expect(described_class.new.sidekiq).to be_a(Esse::AsyncIndexing::Configuration::Sidekiq)
    end

    it "yields the configuration" do
      described_class.new.sidekiq do |config|
        expect(config).to be_a(Esse::AsyncIndexing::Configuration::Sidekiq)
      end
    end
  end

  describe "#services" do
    let(:instance) { described_class.new }

    it "returns an instance of Esse::AsyncIndexing::ConfigService" do
      expect(instance.services).to be_a(Esse::AsyncIndexing::ConfigService)
    end

    it "returns true for sidekiq? if sidekiq is configured" do
      expect(instance.services.sidekiq?).to be(false)
      instance.sidekiq
      expect(instance.services.sidekiq?).to be(true)
    end

    it "returns true for faktory? if faktory is configured" do
      expect(instance.services.faktory?).to be(false)
      instance.faktory
      expect(instance.services.faktory?).to be(true)
    end
  end
end
