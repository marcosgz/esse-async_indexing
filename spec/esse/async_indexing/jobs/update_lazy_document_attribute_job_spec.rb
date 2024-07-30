# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/update_lazy_document_attribute_job"

RSpec.describe Esse::AsyncIndexing::Jobs::UpdateLazyDocumentAttributeJob do
  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpdateLazyDocumentAttributeJob.call" do
      expect(Esse::AsyncIndexing::Actions::UpdateLazyDocumentAttribute).to receive(:call).with("VenuesIndex", "venue", "total_events", [1, 2], {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", "total_events", [1, 2], {})
    end
  end
end
