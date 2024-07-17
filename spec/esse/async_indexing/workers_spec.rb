# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Workers do
  describe ".install!" do
    after do
      described_class.instance_variable_set(:@installed_services, nil)
    end

    context "when installing :faktory" do
      let(:job_class) { Class.new }

      before do
        stub_const("Esse::AsyncIndexing::Workers::DEFAULT", {
          "esse/path" => "Esse::AsyncIndexing::DummyJob"
        })
      end

      it "requires all the jobs from DEFAULT constant and extend them with the faktory adapter" do
        expect(Kernel).to receive(:require).with("esse/path")
        expect(Esse::AsyncIndexing::Jobs).to receive(:const_get).with("DummyJob").and_return(job_class)

        expect {
          described_class.install!("faktory")
        }.to change { described_class.instance_variable_get(:@installed_services) }.from(nil).to([:faktory])
        expect(job_class.methods).to include(:service_worker_options)
      end
    end

    context "when installing :sidekiq" do
      let(:job_class) { Class.new }

      before do
        stub_const("Esse::AsyncIndexing::Workers::DEFAULT", {
          "esse/path" => "Esse::AsyncIndexing::DummyJob"
        })
      end

      it "requires all the jobs from DEFAULT constant and extend them with the sidekiq adapter" do
        expect(Kernel).to receive(:require).with("esse/path")
        expect(Esse::AsyncIndexing::Jobs).to receive(:const_get).with("DummyJob").and_return(job_class)

        expect {
          described_class.install!("sidekiq")
        }.to change { described_class.instance_variable_get(:@installed_services) }.from(nil).to([:sidekiq])
        expect(job_class.methods).to include(:service_worker_options)
      end
    end

    context "when it is already installed" do
      before do
        described_class.instance_variable_set(:@installed_services, %i[faktory sidekiq])
      end

      it "does nothing when the :faktory is already installed" do
        expect(described_class).not_to receive(:for)

        described_class.install!("faktory")
      end

      it "does nothing when the :sidekiq is already installed" do
        expect(described_class).not_to receive(:for)

        described_class.install!("sidekiq")
      end
    end
  end
end
