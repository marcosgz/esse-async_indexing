# frozen_string_literal: true

module Esse
  module Plugins
    module AsyncIndexing
      module RepositoryClassMethods
        DEFAULT_ASYNC_INDEXING_JOBS = {
          import: ->(service:, repo:, operation:, ids:, **kwargs) {
            unless (ids = Esse::ArrayUtils.wrap(ids)).empty?
              batch_id = Esse::RedisStorage::Queue.for(repo: repo).enqueue(values: ids)
              Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::ImportBatchIdJob", service: service)
                .with_args(repo.index.name, repo.repo_name, batch_id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
                .push
            end
          },
          index: ->(service:, repo:, operation:, id:, **kwargs) {
            if id
              Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob", service: service)
                .with_args(repo.index.name, repo.repo_name, id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
                .push
            end
          },
          update: ->(service:, repo:, operation:, id:, **kwargs) {
            if id
              Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob", service: service)
                .with_args(repo.index.name, repo.repo_name, id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
                .push
            end
          },
          delete: ->(service:, repo:, operation:, id:, **kwargs) {
            if id
              Esse::AsyncIndexing.worker("Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob", service: service)
                .with_args(repo.index.name, repo.repo_name, id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
                .push
            end
          }
        }.freeze

        # This method is used to retrieve only the ids of the documents in the collection.
        # It's used to asynchronously index the documents.
        # The #each_batch_ids method is optional and should be implemented by the collection class.
        #
        # @return [Enumerator] The enumerator
        def batch_ids(*args, **kwargs, &block)
          if implement_batch_ids?
            Enumerator.new do |yielder|
              @collection_proc.new(*args, **kwargs).each_batch_ids do |batch|
                yielder.yield(batch)
              end
            end
          else
            raise NotImplementedError, format("the %<t>p collection does not implement the #each_batch_ids method", t: @collection_proc)
          end
        end

        # Check if the collection class implements the each_batch_ids method
        #
        # @return [Boolean] True if the collection class implements the each_batch_ids method
        # @see #each_batch_ids
        def implement_batch_ids?
          @collection_proc.is_a?(Class) && @collection_proc.instance_methods.include?(:each_batch_ids)
        end

        # DSL to define custom job enqueueing
        #
        # async_indexing_job(:import) do |service:, repo:, operation:, ids:, **kwargs|
        #   MyCustomJob.perform_later(repo.index.name, ids, **kwargs)
        # end
        # async_indexing_job(:index, :update, :delete) do |service:, repo:, operation:, id, **kwargs|
        #   MyCustomJob.perform_later(repo.index.name, [id], **kwargs)
        # end
        def async_indexing_job(*operations, &block)
          operations = AsyncIndexingJobValidator::OPERATIONS if operations.empty?
          AsyncIndexingJobValidator.call(operations, block)
          hash = operations.each_with_object({}) { |operation, h| h[operation] = block }
          @async_indexing_jobs = async_indexing_jobs.dup.merge(hash)
        ensure
          @async_indexing_jobs.freeze
        end

        def async_indexing_jobs
          @async_indexing_jobs || {}.freeze
        end

        def async_indexing_job_for(operation)
          async_indexing_jobs[operation] || DEFAULT_ASYNC_INDEXING_JOBS[operation] || raise(ArgumentError, "The #{operation} operation is not implemented")
        end

        class AsyncIndexingJobValidator
          OPERATIONS = %i[import index update delete].freeze

          def self.call(operations, block)
            unless block.is_a?(Proc)
              raise ArgumentError, "The block of async_indexing_job must be a callable object"
            end

            operations.each do |operation|
              next if OPERATIONS.include?(operation)
              raise ArgumentError, format("Unrecognized operation: %<operation>p. Valid operations are: %<valid>p", operation: operation, valid: OPERATIONS)
            end
          end
        end
      end
    end
  end
end
