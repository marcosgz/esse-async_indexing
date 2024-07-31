# frozen_string_literal: true

require "spec_helper"
require "esse/active_record"
require "esse/async_indexing/active_record"

# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Esse::AsyncIndexing::ActiveRecordCallbacks::OnUpdate do
  let(:callback) do
    described_class.new(repo: PostsIndex.repo(:post), service_name: :service)
  end

  before do
    Thread.current[:custom_job] = nil
    stub_esse_index(:posts) do
      plugin :async_indexing
      repository :post, const: true do
        async_indexing_job(:index) { |**kwargs| (Thread.current[:custom_job] ||= []) << kwargs }
        async_indexing_job(:update) { |**kwargs| (Thread.current[:custom_job] ||= []) << kwargs }
      end
    end
  end

  describe "#call" do
    let(:model) { OpenStruct.new(id: 1) }

    before do
      allow(model).to receive(:is_a?).with(ActiveRecord::Base).and_return(true)
    end

    it "calls the async indexing job" do
      expect(callback.call(model)).to be(true)
      expect(Thread.current[:custom_job]).to eq([service: :service, repo: PostsIndex.repo(:post), operation: :index, id: 1])
    end

    context "when with is update" do
      let(:callback) do
        described_class.new(repo: PostsIndex.repo(:post), service_name: :service, with: :update)
      end

      it "calls the async indexing job with update" do
        expect(callback.call(model)).to be(true)
        expect(Thread.current[:custom_job]).to eq([service: :service, repo: PostsIndex.repo(:post), operation: :update, id: 1])
      end
    end

    context "when with is index" do
      let(:callback) do
        described_class.new(repo: PostsIndex.repo(:post), service_name: :service, with: :index)
      end

      it "calls the async indexing job with index" do
        expect(callback.call(model)).to be(true)
        expect(Thread.current[:custom_job]).to eq([service: :service, repo: PostsIndex.repo(:post), operation: :index, id: 1])
      end
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
