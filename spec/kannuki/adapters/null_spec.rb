# frozen_string_literal: true

RSpec.describe Kannuki::Adapters::Null do
  subject(:adapter) { described_class.new }

  describe '#acquire_lock' do
    it 'returns true for available lock' do
      result = adapter.acquire_lock('test_lock', timeout: nil, shared: false, transaction: false)

      expect(result).to be true
    end

    it 'returns false for simulated held lock' do
      Kannuki::Testing.simulate_lock_held('test_lock')

      result = adapter.acquire_lock('test_lock', timeout: nil, shared: false, transaction: false)

      expect(result).to be false
    end
  end

  describe '#release_lock' do
    it 'returns true' do
      adapter.acquire_lock('test_lock', timeout: nil, shared: false, transaction: false)
      result = adapter.release_lock('test_lock', transaction: false)

      expect(result).to be true
    end
  end

  describe '#lock_exists?' do
    it 'returns false when lock not acquired' do
      expect(adapter.lock_exists?('test_lock')).to be false
    end

    it 'returns true when lock acquired' do
      adapter.acquire_lock('test_lock', timeout: nil, shared: false, transaction: false)

      expect(adapter.lock_exists?('test_lock')).to be true
    end

    it 'returns true for simulated held lock' do
      Kannuki::Testing.simulate_lock_held('test_lock')

      expect(adapter.lock_exists?('test_lock')).to be true
    end
  end

  describe '#supports_shared_locks?' do
    it 'returns true' do
      expect(adapter.supports_shared_locks?).to be true
    end
  end

  describe '#supports_transaction_locks?' do
    it 'returns true' do
      expect(adapter.supports_transaction_locks?).to be true
    end
  end

  describe '#clear!' do
    it 'clears all locks' do
      adapter.acquire_lock('lock1', timeout: nil, shared: false, transaction: false)
      adapter.acquire_lock('lock2', timeout: nil, shared: false, transaction: false)
      adapter.clear!

      expect(adapter.lock_exists?('lock1')).to be false
      expect(adapter.lock_exists?('lock2')).to be false
    end
  end
end
