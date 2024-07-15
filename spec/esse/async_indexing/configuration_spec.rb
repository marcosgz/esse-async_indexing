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
end
