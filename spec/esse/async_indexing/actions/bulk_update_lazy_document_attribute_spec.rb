# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Actions::BulkUpdateLazyDocumentAttribute do
  before do
    setup_esse_client!
    stub_esse_index(:geos) do
      repository :city do
        collection { |**, &block| block.call([{id: 1, name: "City 1"}]) }
        document { |hash, **| {_id: hash[:id], name: hash[:name]} }
        lazy_document_attribute :total_neighborhoods do |docs|
          docs.map { |doc| [doc.id, 10] }.to_h
        end
      end
    end
  end

  describe ".call" do
    let(:city_ids) { [1] }

    context "when the batch_id does not exist" do
      let(:batch_id) { SecureRandom.uuid }

      it "does nothing" do
        expect(GeosIndex.repo(:city)).not_to receive(:import) # rubocop:disable RSpec/MessageSpies

        expect(described_class.call("GeosIndex", "city", "total_neighborhoods", batch_id)).to eq([])
      end
    end

    context "when the batch_id exists" do
      let(:batch_id) { SecureRandom.uuid }

      before do
        Esse::RedisStorage::Queue.for(repo: GeosIndex.repo(:city), attribute_name: "total_neighborhoods").enqueue(id: batch_id, values: city_ids)
      end

      it "imports all documents for the batch_id" do
        expect(GeosIndex).to esse_receive_request(:bulk).with(
          index: GeosIndex.index_name,
          body: city_ids.map do |id|
            {update: {_id: id, data: {doc: {total_neighborhoods: 10}}}}
          end
        ).and_return("items" => [])

        expect(described_class.call("GeosIndex", "city", "total_neighborhoods", batch_id)).to eq([1])
      end

      it "imports all documents for the batch_id with options" do
        expect(GeosIndex).to esse_receive_request(:bulk).with(
          index: GeosIndex.index_name(suffix: "2024"),
          body: city_ids.map do |id|
            {update: {_id: id, data: {doc: {total_neighborhoods: 10}}}}
          end,
          refresh: true
        ).and_return("items" => [])

        expect(described_class.call("GeosIndex", "city", "total_neighborhoods", batch_id, suffix: "2024", refresh: true)).to eq([1])
      end
    end
  end
end
