# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/bulk_update_lazy_document_attribute_job"

RSpec.describe Esse::AsyncIndexing::Jobs::BulkUpdateLazyDocumentAttributeJob do
  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::BulkUpdateLazyDocumentAttribute.call" do
      expect(Esse::AsyncIndexing::Actions::BulkUpdateLazyDocumentAttribute).to receive(:call).with("VenuesIndex", "venue", "total_events", "batch_id", {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", "total_events", "batch_id", {})
    end
  end
end
