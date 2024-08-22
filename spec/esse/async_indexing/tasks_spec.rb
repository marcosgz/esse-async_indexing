# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::AsyncIndexing::Tasks do
  let(:tasks) { described_class.new }

  describe "#user_defined?" do
    shared_examples "a user defined task for" do |task_name|
      it "returns false when the block is not given" do
        expect(tasks.user_defined?(task_name)).to be(false)
      end

      it "returns true when the block is given" do
        tasks.define(task_name) { |**| }
        expect(tasks.user_defined?(task_name)).to be(true)
      end
    end

    it_behaves_like "a user defined task for", :import
    it_behaves_like "a user defined task for", :index
    it_behaves_like "a user defined task for", :update
    it_behaves_like "a user defined task for", :delete
    it_behaves_like "a user defined task for", :update_lazy_attribute
  end

  describe "#define" do
    it "raises an error when the task is invalid" do
      expect { tasks.define(:unknown) {} }.to raise_error(ArgumentError, /Unrecognized task: unknown/)
    end

    shared_examples "a task definition for" do |task_name|
      it "defines a task" do
        task = ->(**) {}
        tasks.define(task_name, &task)
        expect(tasks[task_name]).to eq(task)
      end

      it "raises an error when block is not given" do
        expect { tasks.define(task_name) }.to raise_error(ArgumentError, /The block of task must be a callable object/)
      end

      it "freezes the tasks" do
        tasks.define(task_name) { |**| }
        expect(tasks.instance_variable_get(:@tasks)).to be_frozen
      end
    end

    it_behaves_like "a task definition for", :import
    it_behaves_like "a task definition for", :index
    it_behaves_like "a task definition for", :update
    it_behaves_like "a task definition for", :delete
    it_behaves_like "a task definition for", :update_lazy_attribute

    context "when multiple tasks are defined" do
      it "defines multiple tasks" do
        import_task = ->(**) {}
        tasks.define(:import, :index, &import_task)
        expect(tasks[:import]).to eq(import_task)
        expect(tasks[:index]).to eq(import_task)
      end
    end
  end

  describe "#fetch" do
    it "raises an error when the task is unknown" do
      expect { tasks.fetch(:unknown) }.to raise_error(ArgumentError, /Unknown task: unknown/)
    end

    shared_examples "a task fetch for" do |task_name|
      it "returns the default task" do
        expect(tasks.fetch(task_name)).to be_a(Proc)
      end

      it "returns the user-defined task" do
        task = ->(**) {}
        tasks.define(task_name, &task)
        expect(tasks.fetch(task_name)).to be(task)
      end
    end

    it_behaves_like "a task fetch for", :import
    it_behaves_like "a task fetch for", :index
    it_behaves_like "a task fetch for", :update
    it_behaves_like "a task fetch for", :delete
    it_behaves_like "a task fetch for", :update_lazy_attribute
  end
end
