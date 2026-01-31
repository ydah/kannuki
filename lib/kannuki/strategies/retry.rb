# frozen_string_literal: true

module Kannuki
  module Strategies
    class Retry < Base
      def execute(lock_key, &block)
        attempts = 0
        max_attempts = retry_attempts

        loop do
          attempts += 1
          result = try_acquire_and_execute(lock_key, &block)
          return result if result.acquired?
          return result if attempts >= max_attempts

          sleep(calculate_interval(attempts))
        end
      end

      protected

      def retry_attempts
        options.fetch(:retry_attempts, Kannuki.configuration.retry_attempts)
      end

      def retry_interval
        options.fetch(:retry_interval, Kannuki.configuration.retry_interval)
      end

      def retry_backoff
        options.fetch(:retry_backoff, Kannuki.configuration.retry_backoff)
      end

      def calculate_interval(attempt)
        case retry_backoff
        when :exponential
          retry_interval * (2**(attempt - 1))
        when :linear
          retry_interval * attempt
        else
          retry_interval
        end
      end

      def try_acquire_and_execute(lock_key)
        acquired = adapter.acquire_lock(lock_key, timeout: 0, shared: shared?, transaction: transaction?)

        if acquired
          start_time = Time.now
          Instrumentation.acquired(lock_key, adapter: adapter.adapter_name, duration: 0)
          track_lock(lock_key)

          begin
            result = yield
            duration = Time.now - start_time
            Result.new(lock_key: lock_key, acquired: true, value: result, duration: duration,
                       adapter_name: adapter.adapter_name)
          ensure
            release_start = Time.now
            release_lock(lock_key)
            untrack_lock(lock_key)
            Instrumentation.released(lock_key, adapter: adapter.adapter_name, duration: Time.now - release_start)
          end
        else
          Result.new(lock_key: lock_key, acquired: false)
        end
      end
    end
  end
end
