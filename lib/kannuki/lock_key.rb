# frozen_string_literal: true

require 'digest'

module Kannuki
  class LockKey
    attr_reader :name, :normalized_key, :numeric_key

    MAX_MYSQL_KEY_LENGTH = 64
    POSTGRES_INT8_MAX = 9_223_372_036_854_775_807

    def initialize(name, prefix: nil)
      @name = name.to_s
      @prefix = prefix || Kannuki.configuration.key_prefix
      @normalized_key = build_normalized_key
      @numeric_key = build_numeric_key
    end

    def to_s
      @normalized_key
    end

    def to_i
      @numeric_key
    end

    def ==(other)
      case other
      when LockKey
        normalized_key == other.normalized_key
      when String
        normalized_key == other
      when Integer
        numeric_key == other
      else
        false
      end
    end
    alias eql? ==

    def hash
      normalized_key.hash
    end

    class << self
      def from_record(record, scope: nil)
        parts = [record.class.table_name, record.id]
        parts.unshift(record.public_send(scope)) if scope
        new(parts.join('/'))
      end

      def from_job(job, key: nil)
        if key.respond_to?(:call)
          new(key.call(job))
        elsif key
          new(key.to_s)
        else
          new("#{job.class.name}/#{job.arguments.map(&:to_s).join('-')}")
        end
      end
    end

    private

    def build_normalized_key
      base = @prefix ? "#{@prefix}/#{@name}" : @name
      if base.bytesize > MAX_MYSQL_KEY_LENGTH
        "#{base[0, 31]}:#{Digest::MD5.hexdigest(base)}"
      else
        base
      end
    end

    def build_numeric_key
      Digest::MD5.hexdigest(@normalized_key).to_i(16) % POSTGRES_INT8_MAX
    end
  end
end
