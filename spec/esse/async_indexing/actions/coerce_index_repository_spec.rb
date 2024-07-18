# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Actions::CoerceIndexRepository do
  describe ".call" do
    context "with an invalid index class name" do
      it "raises an ArgumentError when the index class is not found" do
        expect { described_class.call("InvalidIndex", "repo") }.to raise_error(ArgumentError, "Index class InvalidIndex not found")
      end
    end

    context "with an invalid repo name" do
      before do
        stub_esse_index(:venues) do
          repository :venue, const: false
        end
      end

      it "raises an ArgumentError when the repo is not found" do
        expect { described_class.call("VenuesIndex", "invalid") }.to raise_error(ArgumentError, /No repo named "invalid" found in VenuesIndex/)
      end
    end

    context "with a valid index class and repo name" do
      before do
        stub_esse_index(:geos) do
          repository :city, const: true
          repository :county, const: true
        end
      end

      it "returns the index class and repo class by passing the repo identifier" do
        expect(described_class.call("GeosIndex", "city")).to eq([GeosIndex, GeosIndex::City])
        expect(described_class.call("GeosIndex", "county")).to eq([GeosIndex, GeosIndex::County])
      end

      it "returns the index class and repo class by passing the repo class name" do
        expect(described_class.call("GeosIndex", "GeosIndex::City")).to eq([GeosIndex, GeosIndex::City])
        expect(described_class.call("GeosIndex", "GeosIndex::County")).to eq([GeosIndex, GeosIndex::County])
      end
    end
  end
end
