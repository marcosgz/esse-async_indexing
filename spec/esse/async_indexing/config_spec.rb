# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Config do
  it "is included in Esse::Config" do
    expect(Esse::Config.included_modules).to include(described_class)
  end

  describe "#async_indexing" do
    it "returns an instance of Esse::AsyncIndexing::Configuration" do
      expect(Esse.config.async_indexing).to be_a(Esse::AsyncIndexing::Configuration)
    end

    it "yields the configuration" do
      Esse.config.async_indexing do |config|
        expect(config).to be_an_instance_of(Esse::AsyncIndexing::Configuration)
      end
    end
  end
end
