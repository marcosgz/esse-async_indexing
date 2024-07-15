# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Esse::AsyncIndexing::Jobs::FaktoryIndexJob" do
  let(:desc_class) { Esse::AsyncIndexing::Jobs::FaktoryIndexJob }

  before do
    Esse.config.async_indexing.faktory # It will require faktory jobs
  end

  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call" do
      expect(Esse::AsyncIndexing::Actions::UpsertDocument).to receive(:call).with("VenuesIndex", "venue", "index", {}).and_return(true)
      desc_class.new.perform("VenuesIndex", "venue", "index", {})
    end
  end
end
