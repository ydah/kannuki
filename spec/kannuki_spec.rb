# frozen_string_literal: true

RSpec.describe Kannuki do
  it 'has a version number' do
    expect(Kannuki::VERSION).not_to be_nil
  end

  describe '.with_lock' do
    it 'delegates to LockManager' do
      executed = false

      result = described_class.with_lock('test_lock') do
        executed = true
        'return_value'
      end

      expect(executed).to be true
      expect(result).to eq 'return_value'
    end
  end

  describe '.try_lock' do
    it 'delegates to LockManager with timeout: 0' do
      executed = false

      result = described_class.try_lock('test_lock') do
        executed = true
        'value'
      end

      expect(executed).to be true
      expect(result).to eq 'value'
    end
  end

  describe '.lock!' do
    it 'delegates to LockManager with on_conflict: :raise' do
      Kannuki::Testing.simulate_lock_held('test_lock')

      expect do
        described_class.lock!('test_lock') { 'value' }
      end.to raise_error(Kannuki::LockNotAcquiredError)
    end
  end

  describe '.locked?' do
    it 'returns false when lock is not held' do
      expect(described_class.locked?('test_lock')).to be false
    end
  end

  describe '.current_locks' do
    it 'returns a Set' do
      expect(described_class.current_locks).to be_a(Set)
    end
  end

  describe '.configure' do
    it 'yields configuration' do
      described_class.configure do |config|
        config.default_timeout = 30
      end

      expect(described_class.configuration.default_timeout).to eq 30
    end
  end
end
