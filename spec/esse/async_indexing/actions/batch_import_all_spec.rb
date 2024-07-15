# frozen_string_literal: true

require "spec_helper"
require "shared_contexts/with_venues_index_definition"

RSpec.describe Esse::AsyncIndexing::Actions::BatchImportAll, freeze_at: [2020, 7, 2, 12, 30, 50] do
  include_context "with venues index definition"

  before do
    setup_esse_client!
  end

  describe ".call" do
    it "imports all documents" do
      expect(VenuesIndex.repo(:venue)).to receive(:import).and_call_original # rubocop:disable RSpec/MessageSpies
      expect(VenuesIndex).to esse_receive_request(:bulk).with(
        index: VenuesIndex.index_name,
        body: venues.map do |venue|
          {index: {_id: venue[:id], data: {name: venue[:name]}}}
        end
      ).and_return("items" => venues.map { |venue| {"index" => {"_id" => venue[:id], "status" => 201}} })
      expect(described_class.call("VenuesIndex", "venue")).to eq(3)
    end

    it "imports all documents with options" do
      expect(VenuesIndex.repo(:venue)).to receive(:import).and_call_original # rubocop:disable RSpec/MessageSpies
      expect(VenuesIndex).to esse_receive_request(:bulk).with(
        index: VenuesIndex.index_name(suffix: "2024"),
        body: venues.map do |venue|
          {index: {_id: venue[:id], data: {name: venue[:name]}}}
        end,
        refresh: true
      ).and_return("items" => venues.map { |venue| {"index" => {"_id" => venue[:id], "status" => 201}} })
      expect(described_class.call("VenuesIndex", "venue", suffix: "2024", refresh: true)).to eq(3)
    end
  end
end
