# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/update_lazy_document_attribute_job"

RSpec.describe Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob do
  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpdateLazyDocumentAttribute.call" do
      expect(Esse::AsyncIndexing::Actions::UpdateLazyDocumentAttribute).to receive(:call).with("VenuesIndex", "venue", "total_events", "batch_id", {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", "total_events", "batch_id", {})
    end
  end
end
