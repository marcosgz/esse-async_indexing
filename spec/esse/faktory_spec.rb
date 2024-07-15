# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing do
  it "has a version number" do
    expect(Esse::AsyncIndexing::VERSION).not_to be_nil
  end
end
