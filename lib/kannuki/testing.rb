# frozen_string_literal: true

require 'set'

module Kannuki
  module Testing
    class << self
      def enable!
        Kannuki.configuration.test_mode = true
        @held_locks = Set.new
      end

      def disable!
        Kannuki.configuration.test_mode = false
        @held_locks = nil
      end

      def clear!
        @held_locks&.clear
      end

      def test_mode?
        Kannuki.configuration.test_mode
      end

      def simulate_lock_held(name)
        @held_locks ||= Set.new
        @held_locks << normalize_key(name)
      end

      def release_simulated_lock(name)
        @held_locks&.delete(normalize_key(name))
      end

      def lock_held?(name)
        @held_locks&.include?(normalize_key(name)) || false
      end

      def held_locks
        @held_locks.to_a
      end

      private

      def normalize_key(name)
        case name
        when LockKey
          name.normalized_key
        else
          name.to_s
        end
      end
    end

    module RSpecHelpers
      def with_kannuki_test_mode
        before { Kannuki::Testing.enable! }
        after { Kannuki::Testing.clear! }
      end
    end

    module Matchers
      if defined?(RSpec::Matchers::DSL)
        extend RSpec::Matchers::DSL

        matcher :acquire_kannuki do |expected_name|
          supports_block_expectations

          match do |block|
            acquired_locks = []

            subscriber = Kannuki::Instrumentation.subscribe('acquired') do |_name, _start, _finish, _id, payload|
              acquired_locks << payload[:lock_key].to_s
            end

            begin
              block.call
            ensure
              Kannuki::Instrumentation.unsubscribe(subscriber)
            end

            acquired_locks.any? { |lock| lock.include?(expected_name.to_s) }
          end

          failure_message do
            "expected block to acquire advisory lock matching '#{expected_name}'"
          end

          failure_message_when_negated do
            "expected block not to acquire advisory lock matching '#{expected_name}'"
          end
        end
      end
    end
  end
end
