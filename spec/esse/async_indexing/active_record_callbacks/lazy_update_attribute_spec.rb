# frozen_string_literal: true

require "spec_helper"
require "esse/active_record"
require "esse/async_indexing/active_record"

# rubocop:disable RSpec/VerifiedDoubles
# rubocop:disable RSpec/ExpectActual
RSpec.describe Esse::AsyncIndexing::ActiveRecordCallbacks::LazyUpdateAttribute, :async_indexing_job do
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

  let(:callback) do
    described_class.new(repo: GeosIndex.repo(:city), service_name: :faktory, attribute_name: :total_neighborhoods)
  end

  describe "#call" do
    let(:model) { OpenStruct.new(id: 1) }

    before do
      allow(model).to receive(:is_a?).with(ActiveRecord::Base).and_return(true)
    end

    it "calls the async indexing job" do
      expect(callback.call(model)).to be(true)

      expect("Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob").to have_enqueued_async_indexing_job(
        "GeosIndex", "city", "total_neighborhoods", [1], {}
      )
    end

    context "when the block_result is a hash" do
      let(:block_result) { {"id" => 1} }

      it "calls the async indexing job" do
        callback.instance_variable_set(:@block_result, block_result)
        expect(callback.call(model)).to be(true)

        expect("Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob").to have_enqueued_async_indexing_job(
          "GeosIndex", "city", "total_neighborhoods", [{"id" => 1}], {}
        )
      end
    end

    context "when the block_result is an array" do
      let(:block_result) { [1, 2] }

      it "calls the async indexing job" do
        callback.instance_variable_set(:@block_result, block_result)
        expect(callback.call(model)).to be(true)

        expect("Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob").to have_enqueued_async_indexing_job(
          "GeosIndex", "city", "total_neighborhoods", [1, 2], {}
        )
      end
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
# rubocop:enable RSpec/ExpectActual
