# frozen_string_literal: true

module Kannuki
  module Adapters
    class MySQL < Base
      def acquire_lock(key, timeout:, shared:, transaction:)
        raise NotSupportedError, 'MySQL does not support shared advisory locks' if shared

        raise NotSupportedError, 'MySQL does not support transaction-scoped advisory locks' if transaction

        string_key = key.is_a?(LockKey) ? key.normalized_key : LockKey.new(key).normalized_key
        timeout_value = timeout || -1

        result = select_value("SELECT GET_LOCK(#{quote(string_key)}, #{timeout_value})")

        case result.to_i
        when 1 then true
        when 0 then false
        else
          raise LockNotAcquiredError.new(string_key), "GET_LOCK returned unexpected value: #{result}"
        end
      end

      def release_lock(key, transaction:)
        string_key = key.is_a?(LockKey) ? key.normalized_key : LockKey.new(key).normalized_key
        result = select_value("SELECT RELEASE_LOCK(#{quote(string_key)})")
        result.to_i == 1
      end

      def lock_exists?(key)
        string_key = key.is_a?(LockKey) ? key.normalized_key : LockKey.new(key).normalized_key
        result = select_value("SELECT IS_USED_LOCK(#{quote(string_key)})")
        !result.nil?
      end

      def supports_shared_locks?
        false
      end

      def supports_transaction_locks?
        false
      end
    end
  end
end
