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
      expect(config.workers).to eq("foo" => {queue: "bar"})
    end
  end
end
