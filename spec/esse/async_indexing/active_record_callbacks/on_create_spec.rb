# frozen_string_literal: true

require "spec_helper"
require "esse/active_record"
require "esse/async_indexing/active_record"

# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Esse::AsyncIndexing::ActiveRecordCallbacks::OnCreate do
  let(:callback) do
    described_class.new(repo: PostsIndex.repo(:post), service_name: :service)
  end

  before do
    Thread.current[:custom_job] = nil
    stub_esse_index(:posts) do
      plugin :async_indexing
      repository :post, const: true do
        async_indexing_job(:index) { |service, repo, op, id, **kwargs| Thread.current[:custom_job] = [service, repo, op, id, kwargs] }
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
      expect(Thread.current[:custom_job]).to eq([:service, PostsIndex.repo(:post), :index, 1, {}])
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
