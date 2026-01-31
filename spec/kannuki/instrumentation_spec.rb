# frozen_string_literal: true

RSpec.describe Kannuki::Instrumentation do
  describe '.instrument' do
    context 'when instrumentation is enabled' do
      before { Kannuki.configuration.enable_instrumentation = true }

      it 'triggers ActiveSupport::Notifications' do
        events = []
        subscriber = described_class.subscribe('test_event') do |*args|
          events << args
        end

        described_class.instrument('test_event', key: 'value') { 'result' }
        described_class.unsubscribe(subscriber)

        expect(events.size).to eq 1
      end

      it 'returns block result' do
        result = described_class.instrument('test_event') { 'block_result' }

        expect(result).to eq 'block_result'
      end
    end

    context 'when instrumentation is disabled' do
      before { Kannuki.configuration.enable_instrumentation = false }

      it 'still executes block' do
        result = described_class.instrument('test_event') { 'block_result' }

        expect(result).to eq 'block_result'
      end
    end
  end

  describe '.subscribe' do
    it 'subscribes to namespaced events' do
      events = []
      subscriber = described_class.subscribe('acquired') do |*args|
        events << args
      end

      ActiveSupport::Notifications.instrument('acquired.kannuki', test: true)
      described_class.unsubscribe(subscriber)

      expect(events.size).to eq 1
    end
  end

  describe '.acquired' do
    it 'instruments lock acquisition' do
      events = []
      subscriber = described_class.subscribe('acquired') do |*args|
        events << args
      end

      described_class.acquired('my_lock', adapter: 'postgresql', duration: 0.1)
      described_class.unsubscribe(subscriber)

      expect(events.size).to eq 1
    end
  end

  describe '.released' do
    it 'instruments lock release' do
      events = []
      subscriber = described_class.subscribe('released') do |*args|
        events << args
      end

      described_class.released('my_lock', adapter: 'postgresql', duration: 0.01)
      described_class.unsubscribe(subscriber)

      expect(events.size).to eq 1
    end
  end

  describe '.failed' do
    it 'instruments lock failure' do
      events = []
      subscriber = described_class.subscribe('failed') do |*args|
        events << args
      end

      described_class.failed('my_lock', adapter: 'postgresql', reason: :timeout, timeout: 30)
      described_class.unsubscribe(subscriber)

      expect(events.size).to eq 1
    end
  end
end
