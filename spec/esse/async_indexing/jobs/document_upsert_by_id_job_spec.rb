# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/document_upsert_by_id_job"

RSpec.describe Esse::AsyncIndexing::Jobs::DocumentUpsertByIdJob do
  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call" do
      expect(Esse::AsyncIndexing::Actions::UpsertDocument).to receive(:call).with("VenuesIndex", "venue", 1, "index", {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", 1, "index", {})
    end
  end
end
