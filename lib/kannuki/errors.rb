# frozen_string_literal: true

module Kannuki
  class Error < StandardError; end

  class LockNotAcquiredError < Error
    attr_reader :lock_key, :timeout

    def initialize(lock_key, timeout: nil)
      @lock_key = lock_key
      @timeout = timeout
      super("Failed to acquire advisory lock: #{lock_key}" +
        (timeout ? " (timeout: #{timeout}s)" : ''))
    end
  end

  class LockTimeoutError < LockNotAcquiredError; end

  class NotSupportedError < Error; end

  class DeadlockError < Error
    attr_reader :lock_key

    def initialize(lock_key)
      @lock_key = lock_key
      super("Deadlock detected while acquiring lock: #{lock_key}")
    end
  end

  class NestedLockError < Error
    def initialize(outer_lock, inner_lock)
      super("Cannot acquire nested advisory lock '#{inner_lock}' " \
            "while holding '#{outer_lock}' (MySQL limitation)")
    end
  end
end
