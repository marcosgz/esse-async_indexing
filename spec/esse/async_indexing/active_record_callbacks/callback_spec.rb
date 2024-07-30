# frozen_string_literal: true

require "spec_helper"
require "esse/active_record"
require "esse/async_indexing/active_record"

# rubocop:disable RSpec/VerifiedDoubles
# rubocop:disable RSpec/AnyInstance
# rubocop:disable RSpec/InstanceVariable
RSpec.describe Esse::AsyncIndexing::ActiveRecordCallbacks::Callback do
  let(:callback_class) do
    Class.new(described_class)
  end
  let(:repo) do
    double("repo")
  end

  describe "initializer" do
    it "sets the service_name" do
      expect(callback_class.new(repo: repo, service_name: :service).service_name).to eq(:service)
    end

    it "sets the with" do
      expect(callback_class.new(repo: repo, service_name: :service, with: :update).instance_variable_get(:@with)).to eq(:update)
    end

    it "sets the block_result" do
      expect(callback_class.new(repo: repo, service_name: :service, block_result: :result).block_result).to eq(:result)
    end

    it "sets the options" do
      expect(callback_class.new(repo: repo, service_name: :service, foo: :bar).options).to eq(foo: :bar)
    end
  end

  describe "#resolve_document_id" do
    let(:callback) { callback_class.new(repo: repo, service_name: :service, **params) }
    let(:params) { {} }

    context "when the model is a ActiveRecord::Base" do
      before do
        stub_const("ActiveRecord::Base", Class.new(OpenStruct) do
          def self.name
            "DummyModel"
          end
        end)
        @model_class = Class.new(ActiveRecord::Base)
      end

      it "returns the document id" do
        model = @model_class.new(id: 1)
        expect(model).to receive(:is_a?).with(ActiveRecord::Base).and_return(true)
        expect(callback.send(:resolve_document_id, model)).to eq(1)
      end

      it "returns the block_result model id when available" do
        model1 = @model_class.new(id: 1)
        model2 = @model_class.new(id: 2)
        expect(model2).to receive(:is_a?).with(ActiveRecord::Base).and_return(true)
        callback.instance_variable_set(:@block_result, model2)
        expect(callback.send(:resolve_document_id, model1)).to eq(2)
      end
    end

    context "when the given value is not a ActiveRecord::Base" do
      it "returns the given value" do
        expect(callback.send(:resolve_document_id, 1)).to eq(1)
      end

      it "returns the block_result when available" do
        callback.instance_variable_set(:@block_result, 2)
        expect(callback.send(:resolve_document_id, 1)).to eq(2)
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
# rubocop:enable RSpec/AnyInstance
# rubocop:enable RSpec/InstanceVariable
