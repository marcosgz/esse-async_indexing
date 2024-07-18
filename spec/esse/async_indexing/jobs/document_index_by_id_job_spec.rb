# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/document_index_by_id_job"

RSpec.describe Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob do
  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions:IndexDocument.call" do
      expect(Esse::AsyncIndexing::Actions::IndexDocument).to receive(:call).with("VenuesIndex", "venue", 1, {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", 1, {})
    end
  end
end
