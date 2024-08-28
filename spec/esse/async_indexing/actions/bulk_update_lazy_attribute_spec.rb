# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Actions::BulkUpdateLazyAttribute do
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
    let(:city_ids) { ["1"] }

    it "imports all documents for the batch_id" do
      expect(GeosIndex).to esse_receive_request(:bulk).with(
        index: GeosIndex.index_name,
        body: city_ids.map do |id|
          {update: {_id: id.to_s, data: {doc: {total_neighborhoods: 10}}}}
        end
      ).and_return("items" => [])

      expect(described_class.call("GeosIndex", "city", "total_neighborhoods", city_ids)).to eq(["1"])
    end

    it "imports all documents for the batch_id with options" do
      expect(GeosIndex).to esse_receive_request(:bulk).with(
        index: GeosIndex.index_name(suffix: "2024"),
        body: city_ids.map do |id|
          {update: {_id: id.to_s, data: {doc: {total_neighborhoods: 10}}}}
        end,
        refresh: true
      ).and_return("items" => [])

      expect(described_class.call("GeosIndex", "city", "total_neighborhoods", city_ids, suffix: "2024", refresh: true)).to eq(["1"])
    end

    it "logs a warning when the lazy attribute is not found" do
      expect(Esse.logger).to receive(:warn).with("Lazy attribute :unknown not found in `city` repository of `GeosIndex` index.")
      expect(described_class.call("GeosIndex", "city", :unknown, city_ids)).to be_nil
    end
  end
end
