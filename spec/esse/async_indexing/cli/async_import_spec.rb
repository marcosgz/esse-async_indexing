# frozen_string_literal: true

require "spec_helper"
require "support/cli_helpers"
require "esse/cli"
require "esse/async_indexing/cli/async_import"

RSpec.describe "Esse::CLI::Index", type: :cli do
  describe "#async_import" do
    it "raises an error if no index name is given" do
      expect {
        cli_exec(%w[index async_import])
      }.to raise_error(Esse::CLI::InvalidOption, /You must specify at least one index class/)
    end

    it "raises an error if given argument is not a valid index class" do
      expect {
        cli_exec(%w[index async_import Esse::Config])
      }.to raise_error(Esse::CLI::InvalidOption, /Esse::Config must be a subclass of Esse::Index/)
    end

    it "raises an error if given argument is not defined" do
      expect {
        cli_exec(%w[index async_import NotDefinedIndexName])
      }.to raise_error(Esse::CLI::InvalidOption, /Unrecognized index class: "NotDefinedIndexName"/)
    end

    context "with a valid index name" do
      before do
        collection_class = Class.new(Esse::Collection) do
          def each_batch_ids
            yield([1, 2, 3])
          end
        end
        stub_esse_index(:counties) do
          repository :county do
            collection collection_class
          end
        end
        stub_esse_index(:cities) do
          plugin :async_indexing
          repository :city do
            collection collection_class
          end
        end
      end

      it "raises an error if the repository does not have the async_indexing plugin" do
        expect {
          cli_exec(%w[index async_import CountiesIndex])
        }.to raise_error(Esse::CLI::InvalidOption, /The CountiesIndex::County repository does not support async indexing/)
      end

      skip "enqueues the async import job for the given index" do
        cli_exec(%w[index async_import CitiesIndex])
      end
    end
  end
end
