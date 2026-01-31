# frozen_string_literal: true

RSpec.describe Kannuki::Strategies::Blocking do
  let(:adapter) { Kannuki::Adapters::Null.new }
  let(:strategy) { described_class.new(adapter, options) }
  let(:options) { {} }

  describe '#execute' do
    it 'executes block when lock is acquired' do
      lock_key = Kannuki::LockKey.new('test_lock')
      executed = false

      result = strategy.execute(lock_key) do
        executed = true
        'return_value'
      end

      expect(executed).to be true
      expect(result.acquired?).to be true
      expect(result.value).to eq 'return_value'
    end

    it 'returns failed result when lock cannot be acquired' do
      Kannuki::Testing.simulate_lock_held('test_lock')
      lock_key = Kannuki::LockKey.new('test_lock')
      executed = false

      result = strategy.execute(lock_key) do
        executed = true
      end

      expect(executed).to be false
      expect(result.acquired?).to be false
    end

    context 'with on_conflict: :raise' do
      let(:options) { { on_conflict: :raise } }

      it 'raises error when lock cannot be acquired' do
        Kannuki::Testing.simulate_lock_held('test_lock')
        lock_key = Kannuki::LockKey.new('test_lock')

        expect do
          strategy.execute(lock_key) {}
        end.to raise_error(Kannuki::LockNotAcquiredError)
      end
    end
  end
end
