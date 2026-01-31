# frozen_string_literal: true

module Kannuki
  module Adapters
    class Base
      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

      def acquire_lock(key, timeout:, shared:, transaction:)
        raise NotImplementedError, 'Subclasses must implement #acquire_lock'
      end

      def release_lock(key, transaction:)
        raise NotImplementedError, 'Subclasses must implement #release_lock'
      end

      def lock_exists?(key)
        raise NotImplementedError, 'Subclasses must implement #lock_exists?'
      end

      def supports_shared_locks?
        false
      end

      def supports_transaction_locks?
        false
      end

      def adapter_name
        self.class.name.split('::').last.downcase
      end

      private

      def quote(value)
        connection.quote(value)
      end

      def execute(sql)
        connection.execute(sql)
      end

      def select_value(sql)
        connection.select_value(sql)
      end
    end
  end
end
