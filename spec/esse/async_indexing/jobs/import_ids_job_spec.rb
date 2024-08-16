# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/import_ids_job"
require "shared_contexts/with_venues_index_definition"

RSpec.describe Esse::AsyncIndexing::Jobs::ImportIdsJob do
  include_context "with venues index definition"

  let(:desc_class) do
    Class.new(Esse::AsyncIndexing::Jobs::ImportIdsJob) do
      extend BackgroundJob.mixin(:faktory)
    end
  end
  let(:ids) { SecureRandom.uuid }

  before do
    Esse.config.async_indexing.faktory
  end

  after do
    reset_config!
  end

  describe ".perform" do
    let(:ids) { [1, 2] }

    it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call" do
      expect(Esse::AsyncIndexing::Actions::BulkImport).to receive(:call).with("VenuesIndex", "venue", ids, {}).and_return(2)
      desc_class.new.perform("VenuesIndex", "venue", ids, {})
    end

    context "when the worker has lazy_document_attributes" do
      before do
        stub_esse_index(:geos) do
          repository :city do
            collection { |**, &block| block.call([{id: 1, name: "City 1"}]) }
            document { |hash, **| {_id: hash[:id], name: hash[:name]} }
            lazy_document_attribute :total_venues do |docs|
              docs.map { |doc| [doc.id, 10] }.to_h
            end
          end
        end
      end

      it "does not enqueue the lazy_document_attributes job when the job does no implement background_job_service" do
        expect(Esse::AsyncIndexing::Actions::BulkImport).to receive(:call).with("GeosIndex", "city", ids, {}).and_return(10)
        described_class.new.perform("GeosIndex", "city", ids, {})
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job
      end

      it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call and enqueues the lazy_document_attributes job" do
        expect(Esse::AsyncIndexing::Actions::BulkImport).to receive(:call).with("GeosIndex", "city", ids, {}).and_return(10)
        desc_class.new.perform("GeosIndex", "city", ids, {})
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_venues", ids, {}).on(:faktory)
      end

      it "does not enqueue the lazy_document_attributes job when the 'eager_include_document_attributes' option is set to true" do
        expect(Esse::AsyncIndexing::Actions::BulkImport).to receive(:call).with("GeosIndex", "city", ids, {"eager_include_document_attributes" => true}).and_return(10)
        desc_class.new.perform("GeosIndex", "city", ids, "eager_include_document_attributes" => true)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job
      end

      it "does not enqueue the lazy_document_attributes job when the 'lazy_update_document_attributes' option is set to true" do
        expect(Esse::AsyncIndexing::Actions::BulkImport).to receive(:call).with("GeosIndex", "city", ids, {"lazy_update_document_attributes" => true}).and_return(10)
        desc_class.new.perform("GeosIndex", "city", ids, "lazy_update_document_attributes" => true)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.not_to have_enqueued_background_job
      end

      it "enqueues the lazy_document_attributes job when the 'lazy_update_document_attributes' or 'eager_include_document_attributes' options are set to false" do
        allow(Esse::AsyncIndexing::Actions::BulkImport).to receive(:call).and_return(10)
        desc_class.new.perform("GeosIndex", "city", ids, "lazy_update_document_attributes" => false)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_venues", ids, {}).on(:faktory)

        clear_enqueued_jobs
        desc_class.new.perform("GeosIndex", "city", ids, "eager_include_document_attributes" => false)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_venues", ids, {}).on(:faktory)

        clear_enqueued_jobs
        desc_class.new.perform("GeosIndex", "city", ids, "lazy_update_document_attributes" => false, "eager_include_document_attributes" => false)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_venues", ids, {}).on(:faktory)
      end
    end
  end
end
