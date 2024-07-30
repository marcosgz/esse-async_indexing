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
      unless callbacks.registered?(:async_update_lazy_attribute, :create)
        callbacks.register_callback(:async_update_lazy_attribute, :create, Esse::AsyncIndexing::ActiveRecordCallbacks::LazyUpdateAttribute)
      end
      unless callbacks.registered?(:async_update_lazy_attribute, :update)
        callbacks.register_callback(:async_update_lazy_attribute, :update, Esse::AsyncIndexing::ActiveRecordCallbacks::LazyUpdateAttribute)
      end
      unless callbacks.registered?(:async_update_lazy_attribute, :destroy)
        callbacks.register_callback(:async_update_lazy_attribute, :destroy, Esse::AsyncIndexing::ActiveRecordCallbacks::LazyUpdateAttribute)
      end
    end

    module ActiveRecordModelClassMethods
      # Define callback on create/update/delete to push a job to the async indexing the document.
      #
      # @param [String] index_repo_name The path of index and repository name.
      #   For example a index with a single repository named `users` is `users`. And a index with
      #   multiple repositories named `animals` and `dog` as the repository name is `animals/dog`.
      #   For namespace, use `/` as the separator.
      # @raise [ArgumentError] when the repo and events are already registered
      # @raise [ArgumentError] when the specified index have multiple repos
      def async_index_callback(index_repo_name, on: %i[create update destroy], with: nil, **options, &block)
        options[:service_name] = ::Esse::AsyncIndexing.service_name(options[:service_name])
        Array(on).each do |event|
          esse_callback(index_repo_name, :async_indexing, on: event, with: with, **options, &block)
        end
      end

      # Define callback on create/update/delete to push a job to the async update a lazy attribute.
      #
      # @param [String] index_repo_name The path of index and repository name.
      #   For example a index with a single repository named `users` is `users`. And a index with
      #   multiple repositories named `animals` and `dog` as the repository name is `animals/dog`.
      #   For namespace, use `/` as the separator.
      # @param [String, Symbol] attribute_name The name of the lazy attribute to update.
      # @raise [ArgumentError] when the repo and events are already registered
      # @raise [ArgumentError] when the specified index have multiple repos
      def async_update_lazy_attribute(index_repo_name, attribute_name, on: %i[create update destroy], **options, &block)
        options[:attribute_name] = attribute_name
        options[:service_name] = ::Esse::AsyncIndexing.service_name(options[:service_name])
        esse_callback(index_repo_name, :async_update_lazy_attribute, identifier_suffix: attribute_name.to_sym, on: on, **options, &block)
      end
    end
  end
end

Esse::AsyncIndexing.__validate_active_record_version!

require_relative "active_record_callbacks/callback"
require_relative "active_record_callbacks/on_create"
require_relative "active_record_callbacks/on_update"
require_relative "active_record_callbacks/on_destroy"
require_relative "active_record_callbacks/lazy_update_attribute"

Esse::AsyncIndexing.__register_active_record_callbacks!
Esse::ActiveRecord::Model::ClassMethods.include(Esse::AsyncIndexing::ActiveRecordModelClassMethods)
