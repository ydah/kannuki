# frozen_string_literal: true

module Kannuki
  module Strategies
    class Base
      attr_reader :adapter, :options

      def initialize(adapter, options = {})
        @adapter = adapter
        @options = options
      end

      def execute(lock_key, &block)
        raise NotImplementedError, 'Subclasses must implement #execute'
      end

      protected

      def timeout
        options.fetch(:timeout, Kannuki.configuration.default_timeout)
      end

      def shared?
        options.fetch(:shared, false)
      end

      def transaction?
        options.fetch(:transaction, false)
      end

      def on_conflict
        options.fetch(:on_conflict, :wait)
      end

      def acquire_lock(lock_key)
        adapter.acquire_lock(lock_key, timeout: timeout, shared: shared?, transaction: transaction?)
      end

      def release_lock(lock_key)
        adapter.release_lock(lock_key, transaction: transaction?)
      end

      def track_lock(lock_key)
        Thread.current[:kannuki_locks] ||= Set.new
        Thread.current[:kannuki_locks] << lock_key.to_s
      end

      def untrack_lock(lock_key)
        Thread.current[:kannuki_locks]&.delete(lock_key.to_s)
      end

      def execute_with_lock(lock_key)
        start_time = Time.now
        acquired = acquire_lock(lock_key)

        if acquired
          duration = Time.now - start_time
          Instrumentation.acquired(lock_key, adapter: adapter.adapter_name, duration: duration)
          track_lock(lock_key)

          begin
            result = yield
            Result.new(lock_key: lock_key, acquired: true, value: result, duration: duration,
                       adapter_name: adapter.adapter_name)
          ensure
            release_start = Time.now
            release_lock(lock_key)
            untrack_lock(lock_key)
            Instrumentation.released(lock_key, adapter: adapter.adapter_name, duration: Time.now - release_start)
          end
        else
          handle_lock_failure(lock_key)
        end
      end

      def handle_lock_failure(lock_key)
        Instrumentation.failed(lock_key, adapter: adapter.adapter_name, reason: :not_acquired, timeout: timeout)

        case on_conflict
        when :raise
          raise LockNotAcquiredError.new(lock_key.to_s, timeout: timeout)
        when :skip
          Result.new(lock_key: lock_key, acquired: false)
        else
          Result.new(lock_key: lock_key, acquired: false)
        end
      end
    end
  end
end
