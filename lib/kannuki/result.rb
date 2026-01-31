# frozen_string_literal: true

module Kannuki
  class Result
    attr_reader :lock_key, :value, :duration, :adapter_name

    def initialize(lock_key:, acquired:, value: nil, duration: nil, adapter_name: nil)
      @lock_key = lock_key
      @acquired = acquired
      @value = value
      @duration = duration
      @adapter_name = adapter_name
    end

    def acquired?
      @acquired
    end

    def success?
      acquired?
    end

    def failed?
      !acquired?
    end

    def to_s
      if acquired?
        "Lock acquired: #{lock_key} (#{duration&.round(3)}s)"
      else
        "Lock not acquired: #{lock_key}"
      end
    end
  end
end
