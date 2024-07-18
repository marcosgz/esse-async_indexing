# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/document_delete_by_id_job"

RSpec.describe Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob do
  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions:DeleteDocument.call" do
      expect(Esse::AsyncIndexing::Actions::DeleteDocument).to receive(:call).with("VenuesIndex", "venue", 1, {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", 1, {})
    end
  end
end
