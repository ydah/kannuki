# frozen_string_literal: true

RSpec.describe Kannuki::Strategies::Retry do
  let(:adapter) { Kannuki::Adapters::Null.new }
  let(:strategy) { described_class.new(adapter, options) }
  let(:options) { { retry_attempts: 3, retry_interval: 0.01 } }

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

    it 'retries when lock is initially held then released' do
      lock_key = Kannuki::LockKey.new('test_lock')
      attempt_count = 0

      Kannuki::Testing.simulate_lock_held('test_lock')

      Thread.new do
        sleep 0.02
        Kannuki::Testing.release_simulated_lock('test_lock')
      end

      result = strategy.execute(lock_key) do
        attempt_count += 1
        'success'
      end

      expect(result.acquired?).to be true
    end

    it 'gives up after max attempts' do
      Kannuki::Testing.simulate_lock_held('test_lock')
      lock_key = Kannuki::LockKey.new('test_lock')

      start_time = Time.now
      result = strategy.execute(lock_key) { 'never' }
      elapsed = Time.now - start_time

      expect(result.acquired?).to be false
      expect(elapsed).to be >= 0.02 # At least 2 retries worth of sleep
    end
  end

  describe 'backoff strategies' do
    context 'with exponential backoff' do
      let(:options) { { retry_attempts: 3, retry_interval: 0.01, retry_backoff: :exponential } }

      it 'uses exponential backoff' do
        expect(strategy.send(:calculate_interval, 1)).to eq 0.01
        expect(strategy.send(:calculate_interval, 2)).to eq 0.02
        expect(strategy.send(:calculate_interval, 3)).to eq 0.04
      end
    end

    context 'with linear backoff' do
      let(:options) { { retry_attempts: 3, retry_interval: 0.01, retry_backoff: :linear } }

      it 'uses linear backoff' do
        expect(strategy.send(:calculate_interval, 1)).to eq 0.01
        expect(strategy.send(:calculate_interval, 2)).to eq 0.02
        expect(strategy.send(:calculate_interval, 3)).to eq 0.03
      end
    end
  end
end
