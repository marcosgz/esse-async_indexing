# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Configuration::Faktory do
  describe "#workers" do
    it "returns a hash" do
      expect(described_class.new.workers).to be_a(Hash)
    end

    it "normalizes the workers" do
      config = described_class.new
      config.workers = {"foo" => {"queue" => "bar"}}
      expect(config.workers["foo"]).to eq(queue: "bar")
    end

    it "does not remove the default workers" do
      config = described_class.new
      config.workers = {"foo" => {"queue" => "bar"}}
      expect(config.workers).to have_key("Esse::AsyncIndexing::Jobs::ImportBatchIdJob")
    end

    it "overwrites the default workers options" do
      config = described_class.new
      config.workers = {"Esse::AsyncIndexing::Jobs::ImportBatchIdJob" => {"queue" => "bar"}}
      expect(config.workers["Esse::AsyncIndexing::Jobs::ImportBatchIdJob"]).to eq(queue: "bar")
    end
  end
end
