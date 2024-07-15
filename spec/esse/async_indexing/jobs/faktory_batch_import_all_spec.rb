# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Esse::AsyncIndexing::Jobs::FaktoryBatchImportAll" do
  let(:desc_class) { Esse::AsyncIndexing::Jobs::FaktoryBatchImportAll }

  before do
    Esse.config.async_indexing.faktory # It will require faktory jobs
  end

  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call" do
      expect(Esse::AsyncIndexing::Actions::BatchImportAll).to receive(:call).with("VenuesIndex", "venue", {}).and_return(true)
      desc_class.new.perform("VenuesIndex", "venue", {})
    end
  end
end
