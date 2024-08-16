# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Events do
  it "registers the batch_ids event" do
    expect(described_class.__bus__.events).to have_key("async_indexing.batch_ids")
  end
end
