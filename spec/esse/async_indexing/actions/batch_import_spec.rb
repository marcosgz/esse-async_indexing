# frozen_string_literal: true

require "spec_helper"
require "shared_contexts/with_venues_index_definition"

RSpec.describe Esse::AsyncIndexing::Actions::BatchImport do
  include_context "with venues index definition"

  before do
    setup_esse_client!
  end

  describe ".call" do
    let(:filtered_venues) { venues[0..1] }
    let(:venue_ids) { filtered_venues.map { |venue| venue[:id].to_s } }

    it "imports all documents" do
      expect(VenuesIndex.repo(:venue)).to receive(:import).and_call_original # rubocop:disable RSpec/MessageSpies
      expect(VenuesIndex).to esse_receive_request(:bulk).with(
        index: VenuesIndex.index_name,
        body: filtered_venues.map do |venue|
          {index: {_id: venue[:id], data: {name: venue[:name]}}}
        end
      ).and_return("items" => filtered_venues.map { |venue| {"index" => {"_id" => venue[:id], "status" => 201}} })
      expect(described_class.call("VenuesIndex", "venue", venue_ids)).to eq(2)
    end

    it "imports all documents with options" do
      expect(VenuesIndex.repo(:venue)).to receive(:import).and_call_original # rubocop:disable RSpec/MessageSpies
      expect(VenuesIndex).to esse_receive_request(:bulk).with(
        index: VenuesIndex.index_name(suffix: "2024"),
        body: filtered_venues.map do |venue|
          {index: {_id: venue[:id], data: {name: venue[:name]}}}
        end,
        refresh: true
      ).and_return("items" => filtered_venues.map { |venue| {"index" => {"_id" => venue[:id], "status" => 201}} })
      expect(described_class.call("VenuesIndex", "venue", venue_ids, suffix: "2024", refresh: true)).to eq(2)
    end
  end
end
