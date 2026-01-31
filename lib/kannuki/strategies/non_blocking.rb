# frozen_string_literal: true

module Kannuki
  module Strategies
    class NonBlocking < Base
      def execute(lock_key, &block)
        execute_with_lock(lock_key, &block)
      end

      protected

      def timeout
        0
      end
    end
  end
end
