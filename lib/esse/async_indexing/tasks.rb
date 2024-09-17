# frozen_string_literal: true

module Esse
  module AsyncIndexing
    class Tasks
      DEFAULT = {
        import: ->(service:, repo:, operation:, ids:, job_options: {}, **kwargs) {
          unless (ids = Esse::ArrayUtils.wrap(ids)).empty?
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::ImportIdsJob", **job_options)
              .with_args(repo.index.name, repo.repo_name, ids, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        },
        index: ->(service:, repo:, operation:, id:, job_options: {}, **kwargs) {
          if id
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob", **job_options)
              .with_args(repo.index.name, repo.repo_name, id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        },
        update: ->(service:, repo:, operation:, id:, job_options: {}, **kwargs) {
          if id
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob", **job_options)
              .with_args(repo.index.name, repo.repo_name, id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        },
        delete: ->(service:, repo:, operation:, id:, job_options: {}, **kwargs) {
          if id
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob", **job_options)
              .with_args(repo.index.name, repo.repo_name, id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        },
        update_lazy_attribute: ->(service:, repo:, operation:, attribute:, ids:, job_options: {}, **kwargs) {
          unless (ids = Esse::ArrayUtils.wrap(ids)).empty?
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob", **job_options)
              .with_args(repo.index.name, repo.repo_name, attribute.to_s, ids, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        }
      }.freeze

      def initialize
        @tasks = {}.freeze
      end

      def user_defined?(name)
        @tasks.key?(name.to_sym)
      end

      def define(*names, &block)
        names = DEFAULT.keys if names.empty?
        validate!(names, block)
        new_tasks = names.each_with_object({}) { |name, h| h[name.to_sym] = block }
        @tasks = @tasks.dup.merge(new_tasks)
      ensure
        @tasks.freeze
      end

      def fetch(name)
        id = name.to_sym
        @tasks[id] || DEFAULT[id] || raise(ArgumentError, "Unknown task: #{name}")
      end
      alias_method :[], :fetch

      def dup
        new_task = self.class.new
        new_task.instance_variable_set(:@tasks, @tasks.dup)
        new_task
      end

      private

      def validate!(names, block)
        unless block.is_a?(Proc)
          raise ArgumentError, "The block of task must be a callable object"
        end

        names.each do |name|
          unless DEFAULT.key?(name)
            raise ArgumentError, "Unrecognized task: #{name}. Valid tasks are: #{DEFAULT.keys}"
          end
        end
      end
    end
  end
end
