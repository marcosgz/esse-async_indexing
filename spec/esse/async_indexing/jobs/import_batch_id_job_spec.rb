# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/import_batch_id_job"

RSpec.describe Esse::AsyncIndexing::Jobs::ImportBatchIdJob do
  let(:batch_id) { SecureRandom.uuid }

  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call" do
      expect(Esse::AsyncIndexing::Actions::ImportBatchId).to receive(:call).with("VenuesIndex", "venue", batch_id, {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", batch_id, {})
    end
  end
end
