# frozen_string_literal: true

module Kannuki
  module Adapters
    class Null < Base
      def initialize(connection = nil)
        @connection = connection
        @locks = {}
      end

      def acquire_lock(key, timeout:, shared:, transaction:)
        string_key = key.is_a?(LockKey) ? key.normalized_key : key.to_s

        return false if Kannuki::Testing.test_mode? && Kannuki::Testing.lock_held?(string_key)

        @locks[string_key] = { shared: shared, transaction: transaction }
        true
      end

      def release_lock(key, transaction:)
        string_key = key.is_a?(LockKey) ? key.normalized_key : key.to_s
        @locks.delete(string_key)
        true
      end

      def lock_exists?(key)
        string_key = key.is_a?(LockKey) ? key.normalized_key : key.to_s
        @locks.key?(string_key) || (Kannuki::Testing.test_mode? && Kannuki::Testing.lock_held?(string_key))
      end

      def supports_shared_locks?
        true
      end

      def supports_transaction_locks?
        true
      end

      def clear!
        @locks.clear
      end
    end
  end
end
