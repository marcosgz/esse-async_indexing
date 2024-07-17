# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/upsert_doc_id_job"

RSpec.describe Esse::AsyncIndexing::Jobs::UpsertDocIdJob do
  before do
    Esse.config.async_indexing.sidekiq # It will require sidekiq jobs
  end

  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call" do
      expect(Esse::AsyncIndexing::Actions::UpsertDocument).to receive(:call).with("VenuesIndex", "venue", "index", {}).and_return(true)
      described_class.new.perform("VenuesIndex", "venue", "index", {})
    end
  end
end
