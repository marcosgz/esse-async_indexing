# frozen_string_literal: true

require "spec_helper"
require "shared_contexts/with_venues_index_definition"

RSpec.describe Esse::AsyncIndexing::Actions::ImportBatchId do
  include_context "with venues index definition"

  before do
    setup_esse_client!
  end

  describe ".call" do
    let(:filtered_venues) { venues[0..1] }
    let(:venue_ids) { filtered_venues.map { |venue| venue[:id].to_s } }

    context "when the batch_id does not exist" do
      let(:batch_id) { SecureRandom.uuid }

      it "does nothing" do
        expect(VenuesIndex.repo(:venue)).not_to receive(:import) # rubocop:disable RSpec/MessageSpies

        expect(described_class.call("VenuesIndex", "venue", batch_id)).to eq(0)
      end
    end

    context "when the batch_id exists" do
      let(:batch_id) { SecureRandom.uuid }

      before do
        Esse::RedisStorage::Queue.for(repo: VenuesIndex.repo(:venue)).enqueue(id: batch_id, values: venue_ids)
      end

      it "imports all documents for the batch_id" do
        expect(VenuesIndex.repo(:venue)).to receive(:import).and_call_original # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to esse_receive_request(:bulk).with(
          index: VenuesIndex.index_name,
          body: filtered_venues.map do |venue|
            {index: {_id: venue[:id], data: {name: venue[:name]}}}
          end
        ).and_return("items" => filtered_venues.map { |venue| {"index" => {"_id" => venue[:id], "status" => 201}} })

        expect(described_class.call("VenuesIndex", "venue", batch_id)).to eq(2)
      end

      it "imports all documents for the batch_id with options" do
        expect(VenuesIndex.repo(:venue)).to receive(:import).and_call_original # rubocop:disable RSpec/MessageSpies
        expect(VenuesIndex).to esse_receive_request(:bulk).with(
          index: VenuesIndex.index_name(suffix: "2024"),
          body: filtered_venues.map do |venue|
            {index: {_id: venue[:id], data: {name: venue[:name]}}}
          end,
          refresh: true
        ).and_return("items" => filtered_venues.map { |venue| {"index" => {"_id" => venue[:id], "status" => 201}} })

        expect(described_class.call("VenuesIndex", "venue", batch_id, suffix: "2024", refresh: true)).to eq(2)
      end
    end
  end
end
