# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Esse::AsyncIndexing::Jobs::SidekiqBatchImportAll" do
  let(:desc_class) { Esse::AsyncIndexing::Jobs::SidekiqBatchImportAll }

  before do
    Esse.config.async_indexing.sidekiq # It will require sidekiq jobs
  end

  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call" do
      expect(Esse::AsyncIndexing::Actions::BatchImportAll).to receive(:call).with("VenuesIndex", "venue", {}).and_return(true)
      desc_class.new.perform("VenuesIndex", "venue", {})
    end
  end
end
