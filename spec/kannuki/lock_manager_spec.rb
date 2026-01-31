# frozen_string_literal: true

RSpec.describe Kannuki::LockManager do
  describe '.with_lock' do
    it 'executes block when lock is acquired' do
      executed = false

      result = described_class.with_lock('test_lock') do
        executed = true
        'return_value'
      end

      expect(executed).to be true
      expect(result).to eq 'return_value'
    end

    it 'returns false when lock cannot be acquired' do
      Kannuki::Testing.simulate_lock_held('test_lock')

      executed = false
      result = described_class.with_lock('test_lock', timeout: 0) do
        executed = true
      end

      expect(executed).to be false
      expect(result).to be false
    end

    it 'supports timeout option' do
      result = described_class.with_lock('test_lock', timeout: 5) do
        'success'
      end

      expect(result).to eq 'success'
    end

    it 'supports shared option' do
      result = described_class.with_lock('test_lock', shared: true) do
        'success'
      end

      expect(result).to eq 'success'
    end
  end

  describe '.try_lock' do
    it 'returns block result when lock is available' do
      result = described_class.try_lock('test_lock') do
        'success'
      end

      expect(result).to eq 'success'
    end

    it 'returns false immediately when lock is held' do
      Kannuki::Testing.simulate_lock_held('test_lock')

      result = described_class.try_lock('test_lock') do
        'should not execute'
      end

      expect(result).to be false
    end
  end

  describe '.lock!' do
    it 'executes block when lock is acquired' do
      result = described_class.lock!('test_lock') do
        'success'
      end

      expect(result).to eq 'success'
    end

    it 'raises error when lock cannot be acquired' do
      Kannuki::Testing.simulate_lock_held('test_lock')

      expect do
        described_class.lock!('test_lock') {}
      end.to raise_error(Kannuki::LockNotAcquiredError)
    end
  end

  describe '.locked?' do
    it 'returns false when lock is not held' do
      expect(described_class.locked?('test_lock')).to be false
    end

    it 'returns true when lock is simulated as held' do
      Kannuki::Testing.simulate_lock_held('test_lock')

      expect(described_class.locked?('test_lock')).to be true
    end
  end

  describe '.current_locks' do
    it 'returns empty set initially' do
      expect(described_class.current_locks).to be_empty
    end

    it 'tracks acquired locks' do
      described_class.with_lock('test_lock') do
        expect(described_class.current_locks).to include('test_lock')
      end
    end

    it 'removes lock after block completes' do
      described_class.with_lock('test_lock') {}

      expect(described_class.current_locks).not_to include('test_lock')
    end
  end

  describe '.holding_lock?' do
    it 'returns false when not holding lock' do
      expect(described_class.holding_lock?('test_lock')).to be false
    end

    it 'returns true inside with_lock block' do
      described_class.with_lock('test_lock') do
        expect(described_class.holding_lock?('test_lock')).to be true
      end
    end
  end
end
