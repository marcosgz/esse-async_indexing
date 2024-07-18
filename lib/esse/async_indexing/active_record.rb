# frozen_string_literal: true

module Esse
  module AsyncIndexing
    ESSE_ACTIVE_RECORD_MINIMAL_VERSION = ::Gem::Version.new("0.3.5")

    def self.__validate_active_record_version!
      unless defined?(Esse::ActiveRecord::Callbacks)
        raise <<~MSG
          To use async indexing ActiveRecord callbacks you need to install and require the `esse-active_record` gem.

          Add this line to your application's Gemfile:
          gem 'esse-active_record', '~> 0.3.5'
        MSG
      end
      require "esse/active_record/version"
      if ::Gem::Version.new(Esse::ActiveRecord::VERSION) < ESSE_ACTIVE_RECORD_MINIMAL_VERSION
        raise <<~MSG
          The esse-active_record gem version #{ESSE_ACTIVE_RECORD_MINIMAL_VERSION} or higher is required. Please update the gem to the latest version.
        MSG
      end
    end

    def self.__register_active_record_callbacks!
      callbacks = Esse::ActiveRecord::Callbacks
      unless callbacks.registered?(:async_indexing, :create)
        callbacks.register_callback(:async_indexing, :create, Esse::AsyncIndexing::ActiveRecordCallbacks::OnCreate)
      end
      unless callbacks.registered?(:async_indexing, :update)
        callbacks.register_callback(:async_indexing, :update, Esse::AsyncIndexing::ActiveRecordCallbacks::OnUpdate)
      end
      unless callbacks.registered?(:async_indexing, :destroy)
        callbacks.register_callback(:async_indexing, :destroy, Esse::AsyncIndexing::ActiveRecordCallbacks::OnDestroy)
      end
    end
  end
end

Esse::AsyncIndexing.__validate_active_record_version!

require_relative "active_record_callbacks/callback"
require_relative "active_record_callbacks/on_create"
require_relative "active_record_callbacks/on_update"
require_relative "active_record_callbacks/on_destroy"

Esse::AsyncIndexing.__register_active_record_callbacks!

