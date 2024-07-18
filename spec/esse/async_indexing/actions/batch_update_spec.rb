# frozen_string_literal: true

require "spec_helper"
require "shared_contexts/with_venues_index_definition"

RSpec.describe Esse::AsyncIndexing::Actions::BatchUpdate do
  include_context "with venues index definition"

  before do
    setup_esse_client!
  end

  describe ".call" do
    let(:filtered_venues) { venues[0..1] }
    let(:venue_ids) { filtered_venues.map { |venue| venue[:id].to_s } }

    it "updates all documents" do
      expect(VenuesIndex).to esse_receive_request(:bulk).with(
        index: VenuesIndex.index_name,
        body: filtered_venues.map do |venue|
          {update: {_id: venue[:id], data: {doc: {name: venue[:name]}}}}
        end
      ).and_return("items" => filtered_venues.map { |venue| {} })
      expect(described_class.call("VenuesIndex", "venue", venue_ids)).to eq(2)
    end

    it "updates all documents with options" do
      expect(VenuesIndex).to esse_receive_request(:bulk).with(
        index: VenuesIndex.index_name(suffix: "2024"),
        body: filtered_venues.map do |venue|
          {update: {_id: venue[:id], data: {doc: {name: venue[:name]}}}}
        end,
        refresh: true
      ).and_return("items" => filtered_venues.map { |venue| {} })
      expect(described_class.call("VenuesIndex", "venue", venue_ids, suffix: "2024", refresh: true)).to eq(2)
    end

    context "when the index have lazy attributes" do
      before do
        stub_esse_index(:geos) do
          repository :city do
            collection { |**, &block| block.call([{id: 1, name: "City 1"}]) }
            document { |hash, **| {_id: hash[:id], name: hash[:name] } }
            lazy_document_attribute :total_venues do |docs|
              docs.map { |doc| [doc.id, 10] }.to_h
            end
          end
        end
      end

      it "updates all documents without eager loading lazy attributes" do
        expect(GeosIndex).to esse_receive_request(:bulk).with(
          index: GeosIndex.index_name,
          body: [
            {update: {_id: 1, data: {doc: {name: "City 1"}}}}
          ]
        ).and_return("items" => [{}])
        expect(described_class.call("GeosIndex", "city", [1], lazy_attributes: false)).to eq(1)
      end

      it "updates all documents with eager loading lazy attributes" do
        expect(GeosIndex).to esse_receive_request(:bulk).with(
          index: GeosIndex.index_name,
          body: [
            {update: {_id: 1, data: {doc: {name: "City 1", total_venues: 10}}}}
          ]
        ).and_return("items" => [{}])
        expect(described_class.call("GeosIndex", "city", [1], lazy_attributes: true)).to eq(1)
      end
    end
  end
end
