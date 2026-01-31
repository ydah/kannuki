# frozen_string_literal: true

module Kannuki
  module Strategies
    class Blocking < Base
      def execute(lock_key, &block)
        Instrumentation.waiting(lock_key, adapter: adapter.adapter_name) if timeout.nil?
        execute_with_lock(lock_key, &block)
      end
    end
  end
end
