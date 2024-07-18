# frozen_string_literal: true

require "spec_helper"
require "esse/active_record"
require "esse/async_indexing/active_record"

RSpec.describe "esse/async_indexing/active_record" do # rubocop:disable RSpec/DescribeClass
  describe "file requires" do
    it "requires the necessary files" do
      expect(defined?(Esse::AsyncIndexing::ActiveRecordCallbacks::OnCreate)).to eq("constant")
      expect(defined?(Esse::AsyncIndexing::ActiveRecordCallbacks::OnUpdate)).to eq("constant")
      expect(defined?(Esse::AsyncIndexing::ActiveRecordCallbacks::OnDestroy)).to eq("constant")
    end

    it "registers the callbacks" do
      expect(Esse::ActiveRecord::Callbacks.registered?(:async_indexing, :create)).to be(true)
      expect(Esse::ActiveRecord::Callbacks.registered?(:async_indexing, :update)).to be(true)
      expect(Esse::ActiveRecord::Callbacks.registered?(:async_indexing, :destroy)).to be(true)
    end

    it "raises an error if the esse-active_record plugin is not defined" do
      stub_const("Esse::ActiveRecord", Module.new)
      expect {
        Esse::AsyncIndexing.__validate_active_record_version!
      }.to raise_error(/To use async indexing ActiveRecord callbacks you need to install and require the `esse-active_record` gem./)
    end

    it "raises an error if the esse-active_record plugin version is less than 0.3.5" do
      stub_const("Esse::ActiveRecord::VERSION", "0.3.4")
      expect {
        Esse::AsyncIndexing.__validate_active_record_version!
      }.to raise_error(/The esse-active_record gem version 0.3.5 or higher is required/)
    end

    it "does not raise an error if the esse-active_record plugin version is 0.3.5" do
      stub_const("Esse::ActiveRecord::VERSION", "0.3.5")
      expect {
        Esse::AsyncIndexing.__validate_active_record_version!
      }.not_to raise_error
    end
  end
end
