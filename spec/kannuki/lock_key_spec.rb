# frozen_string_literal: true

RSpec.describe Kannuki::LockKey do
  describe '#initialize' do
    it 'creates a lock key from string' do
      key = described_class.new('my_lock')

      expect(key.name).to eq 'my_lock'
      expect(key.normalized_key).to eq 'my_lock'
    end

    it 'creates a lock key from symbol' do
      key = described_class.new(:my_lock)

      expect(key.name).to eq 'my_lock'
    end

    it 'applies prefix when provided' do
      key = described_class.new('my_lock', prefix: 'app')

      expect(key.normalized_key).to eq 'app/my_lock'
    end

    it 'applies global prefix from configuration' do
      Kannuki.configure { |c| c.key_prefix = 'global' }
      key = described_class.new('my_lock')

      expect(key.normalized_key).to eq 'global/my_lock'
    end

    it 'truncates long keys with hash' do
      long_name = 'a' * 100
      key = described_class.new(long_name)

      expect(key.normalized_key.bytesize).to be <= 64
      expect(key.normalized_key).to include(':')
    end
  end

  describe '#numeric_key' do
    it 'returns consistent numeric value for same key' do
      key1 = described_class.new('test_lock')
      key2 = described_class.new('test_lock')

      expect(key1.numeric_key).to eq key2.numeric_key
    end

    it 'returns different numeric values for different keys' do
      key1 = described_class.new('lock_a')
      key2 = described_class.new('lock_b')

      expect(key1.numeric_key).not_to eq key2.numeric_key
    end

    it 'returns value within PostgreSQL bigint range' do
      key = described_class.new('test_lock')

      expect(key.numeric_key).to be < 9_223_372_036_854_775_807
      expect(key.numeric_key).to be >= 0
    end
  end

  describe '#==' do
    it 'compares equal with same normalized key' do
      key1 = described_class.new('test')
      key2 = described_class.new('test')

      expect(key1).to eq key2
    end

    it 'compares equal with string' do
      key = described_class.new('test')

      expect(key).to eq 'test'
    end

    it 'compares not equal with different key' do
      key1 = described_class.new('test1')
      key2 = described_class.new('test2')

      expect(key1).not_to eq key2
    end
  end

  describe '#to_s' do
    it 'returns normalized key' do
      key = described_class.new('test', prefix: 'app')

      expect(key.to_s).to eq 'app/test'
    end
  end

  describe '#to_i' do
    it 'returns numeric key' do
      key = described_class.new('test')

      expect(key.to_i).to eq key.numeric_key
    end
  end

  describe '#hash' do
    it 'returns consistent hash for use in Sets' do
      key = described_class.new('test')

      expect(key.hash).to eq key.normalized_key.hash
    end
  end
end
