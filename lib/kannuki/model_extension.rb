# frozen_string_literal: true

module Kannuki
  module ModelExtension
    extend ActiveSupport::Concern

    class_methods do
      def kannuki(name, scope: nil, **options)
        lock_name = name.to_s

        define_method("with_#{lock_name}_lock") do |lock_options = {}, &block|
          merged_options = options.merge(lock_options).merge(scope: scope)
          lock_key = LockKey.from_record(self, scope: scope)
          LockManager.with_lock(lock_key, **merged_options, &block)
        end

        define_method("try_#{lock_name}_lock") do |lock_options = {}, &block|
          merged_options = options.merge(lock_options).merge(scope: scope, timeout: 0)
          lock_key = LockKey.from_record(self, scope: scope)
          LockManager.with_lock(lock_key, **merged_options, &block)
        end

        define_method("#{lock_name}_lock!") do |lock_options = {}, &block|
          merged_options = options.merge(lock_options).merge(scope: scope, on_conflict: :raise)
          lock_key = LockKey.from_record(self, scope: scope)
          LockManager.with_lock(lock_key, **merged_options, &block)
        end

        define_method("#{lock_name}_locked?") do
          lock_key = LockKey.from_record(self, scope: scope)
          LockManager.locked?(lock_key)
        end
      end
    end

    def with_lock(name, **options, &block)
      lock_key = LockKey.from_record(self, scope: options[:scope])
      LockManager.with_lock("#{lock_key}/#{name}", **options, &block)
    end
  end
end
