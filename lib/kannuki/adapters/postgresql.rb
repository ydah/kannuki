# frozen_string_literal: true

module Kannuki
  module Adapters
    class PostgreSQL < Base
      POLL_INTERVAL = 0.1

      def acquire_lock(key, timeout:, shared:, transaction:)
        numeric_key = key.is_a?(LockKey) ? key.numeric_key : LockKey.new(key).numeric_key

        if transaction
          acquire_transaction_lock(numeric_key, shared: shared)
        else
          acquire_session_lock(numeric_key, timeout: timeout, shared: shared)
        end
      end

      def release_lock(key, transaction:)
        return true if transaction

        numeric_key = key.is_a?(LockKey) ? key.numeric_key : LockKey.new(key).numeric_key
        result = select_value("SELECT pg_advisory_unlock(#{numeric_key})")
        [true, 't'].include?(result)
      end

      def lock_exists?(key)
        numeric_key = key.is_a?(LockKey) ? key.numeric_key : LockKey.new(key).numeric_key
        result = select_value(<<~SQL)
          SELECT EXISTS(
            SELECT 1 FROM pg_locks
            WHERE locktype = 'advisory'
            AND classid = #{(numeric_key >> 32) & 0xFFFFFFFF}
            AND objid = #{numeric_key & 0xFFFFFFFF}
          )
        SQL
        [true, 't'].include?(result)
      end

      def supports_shared_locks?
        true
      end

      def supports_transaction_locks?
        true
      end

      private

      def acquire_session_lock(numeric_key, timeout:, shared:)
        lock_func = shared ? 'pg_advisory_lock_shared' : 'pg_advisory_lock'
        try_func = shared ? 'pg_try_advisory_lock_shared' : 'pg_try_advisory_lock'

        if timeout.nil?
          execute("SELECT #{lock_func}(#{numeric_key})")
          true
        elsif timeout.zero?
          result = select_value("SELECT #{try_func}(#{numeric_key})")
          [true, 't'].include?(result)
        else
          poll_for_lock(try_func, numeric_key, timeout)
        end
      end

      def acquire_transaction_lock(numeric_key, shared:)
        try_func = shared ? 'pg_try_advisory_xact_lock_shared' : 'pg_try_advisory_xact_lock'
        result = select_value("SELECT #{try_func}(#{numeric_key})")
        [true, 't'].include?(result)
      end

      def poll_for_lock(try_func, numeric_key, timeout)
        deadline = Time.now + timeout
        loop do
          result = select_value("SELECT #{try_func}(#{numeric_key})")
          return true if [true, 't'].include?(result)
          return false if Time.now >= deadline

          sleep(POLL_INTERVAL)
        end
      end
    end
  end
end
