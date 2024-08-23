# frozen_string_literal: true

require "spec_helper"
require "shared_contexts/with_venues_index_definition"

RSpec.describe Esse::AsyncIndexing::Actions::UpdateDocument do
  include_context "with venues index definition"

  before do
    setup_esse_client!
  end

  describe ".call" do
    it "updates the document with the given id" do
      expect(VenuesIndex).to receive(:update).and_call_original # rubocop:disable RSpec/MessageSpies
      expect(VenuesIndex).to esse_receive_request(:update).with(
        id: hotel[:id],
        index: VenuesIndex.index_name,
        body: {doc: {name: hotel[:name]}}
      ).and_return("result" => "updated", "_id" => hotel[:id])

      expect(described_class.call("VenuesIndex", "venue", hotel[:id])).to eq(:indexed)
    end

    it "includes the options in the request" do
      expect(VenuesIndex).to receive(:update).and_call_original # rubocop:disable RSpec/MessageSpies
      expect(VenuesIndex).to esse_receive_request(:update).with(
        id: hotel[:id],
        index: VenuesIndex.index_name(suffix: "2024"),
        body: {doc: {name: hotel[:name]}},
        refresh: true
      ).and_return("result" => "updated", "_id" => hotel[:id])

      expect(described_class.call("VenuesIndex", "venue", hotel[:id], eager_load_lazy_attributes: false, refresh: true, suffix: "2024")).to eq(:indexed)
    end

    it "does not send a update request if the document is not found" do
      expect(VenuesIndex).not_to receive(:update) # rubocop:disable RSpec/MessageSpies
      expect(described_class.call("VenuesIndex", "venue", 9999)).to eq(:not_found)
    end
  end
end
