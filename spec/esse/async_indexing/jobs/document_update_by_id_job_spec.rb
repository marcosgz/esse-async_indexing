# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/document_update_by_id_job"

RSpec.describe Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob do
  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions:UpdateDocument.call" do
      expect(Esse::AsyncIndexing::Actions::UpdateDocument).to receive(:call).with("VenuesIndex", "venue", 1, {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", 1, {})
    end
  end
end
