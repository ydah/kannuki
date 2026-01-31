# frozen_string_literal: true

RSpec.describe Kannuki::Configuration do
  subject(:config) { described_class.new }

  describe 'defaults' do
    it 'has nil default_timeout' do
      expect(config.default_timeout).to be_nil
    end

    it 'has :blocking default_strategy' do
      expect(config.default_strategy).to eq :blocking
    end

    it 'has nil key_prefix' do
      expect(config.key_prefix).to be_nil
    end

    it 'has true enable_instrumentation' do
      expect(config.enable_instrumentation).to be true
    end

    it 'has 3 retry_attempts' do
      expect(config.retry_attempts).to eq 3
    end

    it 'has 0.5 retry_interval' do
      expect(config.retry_interval).to eq 0.5
    end

    it 'has :exponential retry_backoff' do
      expect(config.retry_backoff).to eq :exponential
    end

    it 'has :return_false on_failure' do
      expect(config.on_failure).to eq :return_false
    end

    it 'has false test_mode' do
      expect(config.test_mode).to be false
    end
  end

  describe '#logger' do
    it 'returns a Logger by default' do
      expect(config.logger).to be_a(Logger)
    end

    it 'can be set to custom logger' do
      custom_logger = Logger.new($stderr)
      config.logger = custom_logger

      expect(config.logger).to eq custom_logger
    end
  end
end

RSpec.describe Kannuki do
  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(described_class.configuration).to be_a(Kannuki::Configuration)
    end

    it 'returns same instance on multiple calls' do
      expect(described_class.configuration).to be described_class.configuration
    end
  end

  describe '.configure' do
    it 'yields configuration for modification' do
      described_class.configure do |config|
        config.default_timeout = 60
        config.key_prefix = 'myapp'
      end

      expect(described_class.configuration.default_timeout).to eq 60
      expect(described_class.configuration.key_prefix).to eq 'myapp'
    end
  end

  describe '.reset_configuration!' do
    it 'resets configuration to defaults' do
      described_class.configure { |c| c.default_timeout = 99 }
      described_class.reset_configuration!

      expect(described_class.configuration.default_timeout).to be_nil
    end
  end
end
