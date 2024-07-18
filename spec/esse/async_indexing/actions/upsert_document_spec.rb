# frozen_string_literal: true

require "spec_helper"
require "shared_contexts/with_venues_index_definition"

RSpec.describe Esse::AsyncIndexing::Actions::UpsertDocument do
  include_context "with venues index definition"

  before do
    setup_esse_client!
  end

  describe ".call" do
    context "when operation is index" do
      it "indexes the document with the given id" do
        expect(VenuesIndex).to receive(:index).and_call_original # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to esse_receive_request(:index).with(
          id: hotel[:id],
          index: VenuesIndex.index_name,
          body: {name: hotel[:name]}
        ).and_return("result" => "created", "_id" => hotel[:id])

        expect(described_class.call("VenuesIndex", "venue", hotel[:id])).to eq(:indexed)
      end

      it "sends a delete request if the document is not found" do
        expect(VenuesIndex).not_to receive(:index) # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to esse_receive_request(:delete).with(
          id: 9999,
          index: VenuesIndex.index_name
        ).and_return("result" => "deleted")

        expect(described_class.call("VenuesIndex", "venue", 9999)).to eq(:deleted)
      end

      it "includes the options in the request" do
        expect(VenuesIndex).to receive(:index).and_call_original # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to esse_receive_request(:index).with(
          id: hotel[:id],
          index: VenuesIndex.index_name(suffix: "2024"),
          body: {name: hotel[:name]},
          refresh: true
        ).and_return("result" => "created", "_id" => hotel[:id])

        expect(described_class.call("VenuesIndex", "venue", hotel[:id], "index", lazy_attributes: false, refresh: true, suffix: "2024")).to eq(:indexed)
      end
    end

    context "when operation is delete" do
      it "deletes the document with the given id" do
        expect(VenuesIndex.repo(:venue)).not_to receive(:documents) # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to receive(:delete).and_call_original
        expect(VenuesIndex).to esse_receive_request(:delete).with(
          id: hotel[:id],
          index: VenuesIndex.index_name
        ).and_return("result" => "deleted")

        expect(described_class.call("VenuesIndex", "venue", hotel[:id], "delete")).to eq(:deleted)
      end

      it "includes the options in the request" do
        expect(VenuesIndex.repo(:venue)).not_to receive(:documents) # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to receive(:delete).and_call_original
        expect(VenuesIndex).to esse_receive_request(:delete).with(
          id: hotel[:id],
          index: VenuesIndex.index_name(suffix: "2024"),
          refresh: true
        ).and_return("result" => "deleted")

        expect(described_class.call("VenuesIndex", "venue", hotel[:id], "delete", lazy_attributes: false, refresh: true, suffix: "2024")).to eq(:deleted)
      end
    end

    context "when operation is update" do
      it "updates the document with the given id" do
        expect(VenuesIndex).to receive(:update).and_call_original # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to esse_receive_request(:update).with(
          id: hotel[:id],
          index: VenuesIndex.index_name,
          body: {doc: {name: hotel[:name]}}
        ).and_return("result" => "updated", "_id" => hotel[:id])

        expect(described_class.call("VenuesIndex", "venue", hotel[:id], "update")).to eq(:indexed)
      end

      it "sends a delete request if the document is not found" do
        expect(VenuesIndex).not_to receive(:update) # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to esse_receive_request(:delete).with(
          id: 9999,
          index: VenuesIndex.index_name
        ).and_return("result" => "deleted")

        expect(described_class.call("VenuesIndex", "venue", 9999, "update")).to eq(:deleted)
      end

      it "includes the options in the request" do
        expect(VenuesIndex).to receive(:update).and_call_original # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to esse_receive_request(:update).with(
          id: hotel[:id],
          index: VenuesIndex.index_name(suffix: "2024"),
          body: {doc: {name: hotel[:name]}},
          refresh: true
        ).and_return("result" => "updated", "_id" => hotel[:id])

        expect(described_class.call("VenuesIndex", "venue", hotel[:id], "update", lazy_attributes: false, refresh: true, suffix: "2024")).to eq(:indexed)
      end
    end

    context "when operation is not supported" do
      it "raises an ArgumentError" do
        expect { described_class.call("VenuesIndex", "venue", hotel[:id], "invalid") }.to raise_error(ArgumentError, "operation must be one of index, update, delete")
      end
    end
  end
end
