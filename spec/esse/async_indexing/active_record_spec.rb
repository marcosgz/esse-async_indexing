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
      expect(defined?(Esse::AsyncIndexing::ActiveRecordCallbacks::LazyUpdateAttribute)).to eq("constant")
    end

    it "registers the callbacks" do
      expect(Esse::ActiveRecord::Callbacks.registered?(:async_indexing, :create)).to be(true)
      expect(Esse::ActiveRecord::Callbacks.registered?(:async_indexing, :update)).to be(true)
      expect(Esse::ActiveRecord::Callbacks.registered?(:async_indexing, :destroy)).to be(true)
      expect(Esse::ActiveRecord::Callbacks.registered?(:async_update_lazy_attribute, :create)).to be(true)
      expect(Esse::ActiveRecord::Callbacks.registered?(:async_update_lazy_attribute, :update)).to be(true)
      expect(Esse::ActiveRecord::Callbacks.registered?(:async_update_lazy_attribute, :destroy)).to be(true)
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

  describe "ActiveRecordModelClassMethods" do
    let(:model_class) do
      Class.new do
        include Esse::ActiveRecord::Model
      end
    end

    before do
      Esse.config.async_indexing.faktory
    end

    after do
      reset_config!
    end

    it "defines the async_index_callback method" do
      expect(model_class).to respond_to(:async_index_callback)
    end

    it "calls the async_update_lazy_attribute method" do
      expect(model_class).to respond_to(:async_update_lazy_attribute)
    end

    it "calls the esse_callback by setting the async_indexing callback" do
      expect(model_class).to receive(:esse_callback).with("users", :async_indexing, on: :create, with: nil, service_name: :faktory)
      model_class.async_index_callback("users", on: :create)

      expect(model_class).to receive(:esse_callback).with("users", :async_indexing, on: :update, with: nil, service_name: :faktory)
      model_class.async_index_callback("users", on: :update)

      expect(model_class).to receive(:esse_callback).with("users", :async_indexing, on: :destroy, with: nil, service_name: :sidekiq)
      model_class.async_index_callback("users", on: :destroy, service_name: :sidekiq)
    end

    it "calls the esse_callback by setting the async_update_lazy_attribute callback" do
      expect(model_class).to receive(:esse_callback).with("users", :async_update_lazy_attribute, on: :create, identifier_suffix: :msg_count, service_name: :faktory, attribute_name: "msg_count")
      model_class.async_update_lazy_attribute("users", "msg_count", on: :create)

      expect(model_class).to receive(:esse_callback).with("users", :async_update_lazy_attribute, on: :update, identifier_suffix: :msg_count, service_name: :sidekiq, attribute_name: "msg_count")
      model_class.async_update_lazy_attribute("users", "msg_count", on: :update, service_name: :sidekiq)

      expect(model_class).to receive(:esse_callback).with("users", :async_update_lazy_attribute, on: :destroy, identifier_suffix: :msg_count, service_name: :faktory, attribute_name: "msg_count")
      model_class.async_update_lazy_attribute("users", "msg_count", on: :destroy)
    end

    it "raises an error if the service_name is not configured" do
      expect {
        model_class.async_index_callback("users", on: :create, service_name: :unknown)
      }.to raise_error(/Invalid service: :unknown/)

      expect {
        model_class.async_update_lazy_attribute("users", "msg_count", on: :create, service_name: :unknown)
      }.to raise_error(/Invalid service: :unknown/)
    end
  end
end
