# frozen_string_literal: true

module Esse
  module Plugins
    module AsyncIndexing
      module RepositoryClassMethods
        # This method is used to retrieve only the ids of the documents in the collection.
        # It's used to asynchronously index the documents.
        # The #each_batch_ids method is optional and should be implemented by the collection class.
        #
        # @yield [batch] Yields each batch of ids
        # @return [Enumerator] The enumerator
        def batch_ids(*args, **kwargs)
          if implement_batch_ids?
            if block_given?
              @collection_proc.new(*args, **kwargs).each_batch_ids do |batch|
                yield(batch)
              end
            else
              Enumerator.new do |yielder|
                @collection_proc.new(*args, **kwargs).each_batch_ids do |batch|
                  yielder.yield(batch)
                end
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
          definer = @async_indexing_tasks || Esse::AsyncIndexing::Tasks.new
          definer.define(*operations, &block)
          @async_indexing_tasks = definer
        end

        def async_indexing_job?(operation)
          return false unless @async_indexing_tasks

          @async_indexing_tasks.user_defined?(operation)
        end

        def async_indexing_job_for(operation)
          (@async_indexing_tasks || Esse.config.async_indexing.tasks).fetch(operation)
        end
      end
    end
  end
end
