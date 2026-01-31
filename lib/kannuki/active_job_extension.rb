# frozen_string_literal: true

module Kannuki
  module ActiveJobExtension
    extend ActiveSupport::Concern

    class_methods do
      def with_lock(name, key: nil, **options)
        @kannuki_config = { name: name, key: key, options: options }

        around_perform do |job, block|
          config = job.class.instance_variable_get(:@kannuki_config)
          lock_key = LockKey.from_job(job, key: config[:key])
          full_key = "#{config[:name]}/#{lock_key}"

          result = LockManager.with_lock(full_key, **config[:options]) do
            block.call
          end

          raise LockNotAcquiredError, full_key if result == false && config[:options][:on_conflict] != :skip
        end
      end

      def unique_by_lock(on_conflict: :skip, timeout: 0, **options)
        around_perform do |job, block|
          lock_key = "unique/#{job.class.name}/#{job.arguments.map(&:to_s).join('-')}"

          result = LockManager.with_lock(lock_key, timeout: timeout, on_conflict: on_conflict, **options) do
            block.call
          end

          if result == false
            case on_conflict
            when :raise
              raise LockNotAcquiredError, lock_key
            when :skip
              Kannuki.configuration.logger.info(
                "[Kannuki] Skipping duplicate job: #{job.class.name} with args #{job.arguments}"
              )
            end
          end
        end
      end
    end
  end
end
