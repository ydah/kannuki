# frozen_string_literal: true

Kannuki.configure do |config|
  # Default timeout in seconds for acquiring locks.
  # nil means wait indefinitely.
  # config.default_timeout = nil

  # Default strategy for acquiring locks.
  # Options: :blocking, :non_blocking, :retry
  # config.default_strategy = :blocking

  # Prefix for all lock keys (useful for multi-tenant applications).
  # config.key_prefix = Rails.application.class.module_parent_name.underscore

  # Enable ActiveSupport::Notifications instrumentation.
  # config.enable_instrumentation = true

  # Number of retry attempts when using the :retry strategy.
  # config.retry_attempts = 3

  # Interval between retries in seconds.
  # config.retry_interval = 0.5

  # Backoff strategy for retries.
  # Options: :exponential, :linear, :constant
  # config.retry_backoff = :exponential

  # Default behavior when lock acquisition fails.
  # Options: :return_false, :raise
  # config.on_failure = :return_false
end
