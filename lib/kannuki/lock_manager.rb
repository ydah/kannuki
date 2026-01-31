# frozen_string_literal: true

require 'set'

module Kannuki
  class LockManager
    STRATEGY_MAP = {
      blocking: Strategies::Blocking,
      non_blocking: Strategies::NonBlocking,
      retry: Strategies::Retry
    }.freeze

    class << self
      def with_lock(name, **options, &block)
        lock_key = build_lock_key(name, options)
        adapter = resolve_adapter(options[:connection])
        strategy = build_strategy(adapter, options)

        result = strategy.execute(lock_key, &block)

        if result.acquired?
          result.value
        else
          false
        end
      end

      def try_lock(name, **options, &block)
        with_lock(name, **options.merge(timeout: 0), &block)
      end

      def lock!(name, **options, &block)
        with_lock(name, **options.merge(on_conflict: :raise), &block)
      end

      def locked?(name, connection: nil)
        lock_key = build_lock_key(name, {})
        adapter = resolve_adapter(connection)
        adapter.lock_exists?(lock_key)
      end

      def current_locks
        Thread.current[:kannuki_locks] ||= Set.new
      end

      def holding_lock?(name)
        lock_key = build_lock_key(name, {})
        current_locks.include?(lock_key.to_s)
      end

      private

      def build_lock_key(name, options)
        case name
        when LockKey
          name
        when ActiveRecord::Base
          LockKey.from_record(name, scope: options[:scope])
        else
          LockKey.new(name, prefix: options[:prefix])
        end
      end

      def resolve_adapter(connection)
        return Adapters::Null.new if Kannuki.configuration.test_mode

        conn = connection || ActiveRecord::Base.connection
        adapter_name = conn.adapter_name.downcase

        case adapter_name
        when /postgresql/, /postgis/
          Adapters::PostgreSQL.new(conn)
        when /mysql/
          Adapters::MySQL.new(conn)
        else
          Kannuki.configuration.logger.warn(
            "[Kannuki] Unknown adapter '#{adapter_name}', falling back to Null adapter"
          )
          Adapters::Null.new(conn)
        end
      end

      def build_strategy(adapter, options)
        strategy_name = options.fetch(:strategy, Kannuki.configuration.default_strategy)
        strategy_class = STRATEGY_MAP[strategy_name.to_sym]

        raise ArgumentError, "Unknown strategy: #{strategy_name}" unless strategy_class

        strategy_class.new(adapter, options)
      end
    end
  end
end
