# frozen_string_literal: true

require "spec_helper"
require "shared_contexts/with_venues_index_definition"

RSpec.describe Esse::AsyncIndexing::Actions::DeleteDocument do
  include_context "with venues index definition"

  before do
    setup_esse_client!
  end

  describe ".call" do
    it "deletes the document with the given id" do
      expect(VenuesIndex.repo(:venue)).not_to receive(:documents) # rubocop:disable RSpec/MessageSpies
      expect(VenuesIndex).to receive(:delete).and_call_original
      expect(VenuesIndex).to esse_receive_request(:delete).with(
        id: hotel[:id],
        index: VenuesIndex.index_name
      ).and_return("result" => "deleted")

      expect(described_class.call("VenuesIndex", "venue", hotel[:id])).to eq(:deleted)
    end

    it "includes the options in the request" do
      expect(VenuesIndex.repo(:venue)).not_to receive(:documents) # rubocop:disable RSpec/MessageSpies
      expect(VenuesIndex).to receive(:delete).and_call_original
      expect(VenuesIndex).to esse_receive_request(:delete).with(
        id: hotel[:id],
        index: VenuesIndex.index_name(suffix: "2024"),
        refresh: true
      ).and_return("result" => "deleted")

      expect(described_class.call("VenuesIndex", "venue", hotel[:id], eager_load_lazy_attributes: false, refresh: true, suffix: "2024")).to eq(:deleted)
    end

    it "returns :not_found when the document is not found" do
      expect(VenuesIndex.repo(:venue)).not_to receive(:documents) # rubocop:disable RSpec/MessageSpies
      expect(VenuesIndex).to receive(:delete).and_call_original
      expect(VenuesIndex).to esse_receive_request(:delete).with(
        id: hotel[:id],
        index: VenuesIndex.index_name
      ).and_raise(Esse::Transport::NotFoundError)

      expect(described_class.call("VenuesIndex", "venue", hotel[:id])).to eq(:not_found)
    end
  end
end
