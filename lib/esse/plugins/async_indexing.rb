# frozen_string_literal: true

module Esse
  module Plugins
    module AsyncIndexing
      module RepositoryClassMethods
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
      end
    end
  end
end
