# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/import_all_job"

RSpec.describe Esse::AsyncIndexing::Jobs::ImportAllJob do
  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call" do
      expect(Esse::AsyncIndexing::Actions::BulkImportAll).to receive(:call).with("VenuesIndex", "venue", {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", {})
    end
  end
end
