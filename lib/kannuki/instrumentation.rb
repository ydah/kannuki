# frozen_string_literal: true

require 'active_support/notifications'

module Kannuki
  module Instrumentation
    NAMESPACE = 'kannuki'

    class << self
      def instrument(event, payload = {}, &block)
        return yield unless Kannuki.configuration.enable_instrumentation

        ActiveSupport::Notifications.instrument("#{event}.#{NAMESPACE}", payload, &block)
      end

      def subscribe(event, &block)
        ActiveSupport::Notifications.subscribe("#{event}.#{NAMESPACE}", &block)
      end

      def unsubscribe(subscriber)
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      def acquired(lock_key, adapter:, duration:)
        instrument('acquired', lock_key: lock_key, adapter: adapter, duration: duration)
      end

      def released(lock_key, adapter:, duration:)
        instrument('released', lock_key: lock_key, adapter: adapter, duration: duration)
      end

      def failed(lock_key, adapter:, reason:, timeout: nil)
        instrument('failed', lock_key: lock_key, adapter: adapter, reason: reason, timeout: timeout)
      end

      def timeout(lock_key, adapter:, timeout:)
        instrument('timeout', lock_key: lock_key, adapter: adapter, timeout: timeout)
      end

      def waiting(lock_key, adapter:)
        instrument('waiting', lock_key: lock_key, adapter: adapter)
      end
    end
  end
end
