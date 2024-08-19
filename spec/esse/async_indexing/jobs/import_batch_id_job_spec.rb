# frozen_string_literal: true

require "spec_helper"
require "esse/async_indexing/jobs/import_batch_id_job"
require "shared_contexts/with_venues_index_definition"

RSpec.describe Esse::AsyncIndexing::Jobs::ImportBatchIdJob do
  include_context "with venues index definition"

  let(:desc_class) do
    Class.new(Esse::AsyncIndexing::Jobs::ImportBatchIdJob) do
      extend BackgroundJob.mixin(:faktory)
    end
  end
  let(:batch_id) { SecureRandom.uuid }

  before do
    Esse.config.async_indexing.faktory
  end

  after do
    reset_config!
  end

  describe ".perform" do
    it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call" do
      expect(Esse::AsyncIndexing::Actions::ImportBatchId).to receive(:call).with("VenuesIndex", "venue", batch_id, {}).and_return(10)
      desc_class.new.perform("VenuesIndex", "venue", batch_id, {})
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
        expect(Esse::AsyncIndexing::Actions::ImportBatchId).to receive(:call).with("GeosIndex", "city", batch_id, {}).and_return(10)
        described_class.new.perform("GeosIndex", "city", batch_id, {})
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeBatchIdJob" }.not_to have_enqueued_background_job
      end

      it "calls Esse::AsyncIndexing::Actions::UpsertDocument.call and enqueues the lazy_document_attributes job" do
        expect(Esse::AsyncIndexing::Actions::ImportBatchId).to receive(:call).with("GeosIndex", "city", batch_id, {}).and_return(10)
        desc_class.new.perform("GeosIndex", "city", batch_id, {})
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeBatchIdJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_venues", batch_id, {}).on(:faktory)
      end

      it "does not enqueue the lazy_document_attributes job when the 'eager_load_lazy_attributes' option is set to true" do
        expect(Esse::AsyncIndexing::Actions::ImportBatchId).to receive(:call).with("GeosIndex", "city", batch_id, {"eager_load_lazy_attributes" => true}).and_return(10)
        desc_class.new.perform("GeosIndex", "city", batch_id, "eager_load_lazy_attributes" => true)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeBatchIdJob" }.not_to have_enqueued_background_job
      end

      it "does not enqueue the lazy_document_attributes job when the 'update_lazy_attributes' option is set to true" do
        expect(Esse::AsyncIndexing::Actions::ImportBatchId).to receive(:call).with("GeosIndex", "city", batch_id, {"update_lazy_attributes" => true}).and_return(10)
        desc_class.new.perform("GeosIndex", "city", batch_id, "update_lazy_attributes" => true)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeBatchIdJob" }.not_to have_enqueued_background_job
      end

      it "enqueues the lazy_document_attributes job when the 'update_lazy_attributes' or 'eager_load_lazy_attributes' options are set to false" do
        allow(Esse::AsyncIndexing::Actions::ImportBatchId).to receive(:call).and_return(10)
        desc_class.new.perform("GeosIndex", "city", batch_id, "update_lazy_attributes" => false)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeBatchIdJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_venues", batch_id, {}).on(:faktory)

        clear_enqueued_jobs
        desc_class.new.perform("GeosIndex", "city", batch_id, "eager_load_lazy_attributes" => false)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeBatchIdJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_venues", batch_id, {}).on(:faktory)

        clear_enqueued_jobs
        desc_class.new.perform("GeosIndex", "city", batch_id, "update_lazy_attributes" => false, "eager_load_lazy_attributes" => false)
        expect { "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeBatchIdJob" }.to have_enqueued_background_job("GeosIndex", "city", "total_venues", batch_id, {}).on(:faktory)
      end
    end
  end
end
