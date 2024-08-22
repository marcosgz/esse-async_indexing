# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0 - 2024-08-22
* Remove esse-redis_storage dependency
* Remove the batch id jobs and actions related redis storage
* Add the --eager-load-lazy-attributes option to the async_import cli command
* Add the --update-lazy-attributes option to the async_import cli command
* Add the --enqueue-lazy-attributes option to the async_import cli command
* Add the --preload-lazy-attributes option to the async_import cli command
* Add the --job-options option to the async_import cli command
* Update import related jobs to process ids instead of batch id

## 0.0.2 - 2024-08-02
* Include sidekiq and faktory jobs to perform async indexing of documents
* Create Active Model async indexing callbacks
* many bug fixes and improvements

## 0.0.1 - 2024-07-15
The first release of the esse-async_indexing plugin
* Added: Initial implementation of the plugin
