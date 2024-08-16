# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/bulk_update_lazy_attribute_job"

RSpec.describe Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob do
  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::BulkUpdateLazyAttributeJob.call" do
      expect(Esse::AsyncIndexing::Actions::BulkUpdateLazyAttribute).to receive(:call).with("VenuesIndex", "venue", "total_events", [1, 2], {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", "total_events", [1, 2], {})
    end
  end
end
