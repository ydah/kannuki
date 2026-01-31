# frozen_string_literal: true

require 'logger'

module Kannuki
  class Configuration
    attr_accessor :default_timeout, :default_strategy, :key_prefix, :enable_instrumentation, :retry_attempts,
                  :retry_interval, :retry_backoff, :on_failure, :test_mode
    attr_writer :logger

    def initialize
      @default_timeout = nil
      @default_strategy = :blocking
      @key_prefix = nil
      @enable_instrumentation = true
      @logger = nil
      @retry_attempts = 3
      @retry_interval = 0.5
      @retry_backoff = :exponential
      @on_failure = :return_false
      @test_mode = false
    end

    def logger
      @logger ||= if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
                    Rails.logger
                  else
                    Logger.new($stdout)
                  end
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
