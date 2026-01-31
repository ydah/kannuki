# frozen_string_literal: true

RSpec.describe Kannuki::Strategies::NonBlocking do
  let(:adapter) { Kannuki::Adapters::Null.new }
  let(:strategy) { described_class.new(adapter, options) }
  let(:options) { {} }

  describe '#execute' do
    it 'executes block when lock is available' do
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

    it 'returns immediately when lock is held' do
      Kannuki::Testing.simulate_lock_held('test_lock')
      lock_key = Kannuki::LockKey.new('test_lock')
      executed = false

      result = strategy.execute(lock_key) do
        executed = true
      end

      expect(executed).to be false
      expect(result.acquired?).to be false
    end
  end
end
