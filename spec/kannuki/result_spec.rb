# frozen_string_literal: true

RSpec.describe Kannuki::Result do
  describe '#acquired?' do
    it 'returns true when acquired' do
      result = described_class.new(lock_key: 'test', acquired: true)

      expect(result.acquired?).to be true
    end

    it 'returns false when not acquired' do
      result = described_class.new(lock_key: 'test', acquired: false)

      expect(result.acquired?).to be false
    end
  end

  describe '#success?' do
    it 'is an alias for acquired?' do
      result = described_class.new(lock_key: 'test', acquired: true)

      expect(result.success?).to eq result.acquired?
    end
  end

  describe '#failed?' do
    it 'returns true when not acquired' do
      result = described_class.new(lock_key: 'test', acquired: false)

      expect(result.failed?).to be true
    end

    it 'returns false when acquired' do
      result = described_class.new(lock_key: 'test', acquired: true)

      expect(result.failed?).to be false
    end
  end

  describe '#value' do
    it 'returns the stored value' do
      result = described_class.new(lock_key: 'test', acquired: true, value: 'result_value')

      expect(result.value).to eq 'result_value'
    end
  end

  describe '#duration' do
    it 'returns the duration' do
      result = described_class.new(lock_key: 'test', acquired: true, duration: 0.5)

      expect(result.duration).to eq 0.5
    end
  end

  describe '#to_s' do
    it 'formats acquired message' do
      result = described_class.new(lock_key: 'test', acquired: true, duration: 0.123456)

      expect(result.to_s).to eq 'Lock acquired: test (0.123s)'
    end

    it 'formats not acquired message' do
      result = described_class.new(lock_key: 'test', acquired: false)

      expect(result.to_s).to eq 'Lock not acquired: test'
    end
  end
end
