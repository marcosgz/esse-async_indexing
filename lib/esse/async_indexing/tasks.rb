# frozen_string_literal: true

module Esse
  module AsyncIndexing
    class Tasks
      DEFAULT = {
        import: ->(service:, repo:, operation:, ids:, **kwargs) {
          unless (ids = Esse::ArrayUtils.wrap(ids)).empty?
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::ImportIdsJob")
              .with_args(repo.index.name, repo.repo_name, ids, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        },
        index: ->(service:, repo:, operation:, id:, **kwargs) {
          if id
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::DocumentIndexByIdJob")
              .with_args(repo.index.name, repo.repo_name, id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        },
        update: ->(service:, repo:, operation:, id:, **kwargs) {
          if id
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::DocumentUpdateByIdJob")
              .with_args(repo.index.name, repo.repo_name, id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        },
        delete: ->(service:, repo:, operation:, id:, **kwargs) {
          if id
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::DocumentDeleteByIdJob")
              .with_args(repo.index.name, repo.repo_name, id, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        },
        update_lazy_attribute: ->(service:, repo:, operation:, attribute:, ids:, **kwargs) {
          unless (ids = Esse::ArrayUtils.wrap(ids)).empty?
            BackgroundJob.job(service, "Esse::AsyncIndexing::Jobs::BulkUpdateLazyAttributeJob")
              .with_args(repo.index.name, repo.repo_name, attribute.to_s, ids, Esse::HashUtils.deep_transform_keys(kwargs, &:to_s))
              .push
          end
        }
      }.freeze

    end
  end
end
