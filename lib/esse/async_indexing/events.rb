# frozen_string_literal: true

module Esse::AsyncIndexing
  class Events
    include Esse::Events::Publisher

    register_event "async_indexing.batch_ids"
  end
end
