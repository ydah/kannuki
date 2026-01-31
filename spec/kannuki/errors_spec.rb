# frozen_string_literal: true

RSpec.describe Kannuki::Error do
  it 'inherits from StandardError' do
    expect(described_class.superclass).to eq StandardError
  end
end

RSpec.describe Kannuki::LockNotAcquiredError do
  it 'inherits from Kannuki::Error' do
    expect(described_class.superclass).to eq Kannuki::Error
  end

  describe '#initialize' do
    it 'stores lock_key' do
      error = described_class.new('my_lock')

      expect(error.lock_key).to eq 'my_lock'
    end

    it 'stores timeout' do
      error = described_class.new('my_lock', timeout: 30)

      expect(error.timeout).to eq 30
    end

    it 'formats message without timeout' do
      error = described_class.new('my_lock')

      expect(error.message).to eq 'Failed to acquire advisory lock: my_lock'
    end

    it 'formats message with timeout' do
      error = described_class.new('my_lock', timeout: 30)

      expect(error.message).to eq 'Failed to acquire advisory lock: my_lock (timeout: 30s)'
    end
  end
end

RSpec.describe Kannuki::LockTimeoutError do
  it 'inherits from LockNotAcquiredError' do
    expect(described_class.superclass).to eq Kannuki::LockNotAcquiredError
  end
end

RSpec.describe Kannuki::NotSupportedError do
  it 'inherits from Kannuki::Error' do
    expect(described_class.superclass).to eq Kannuki::Error
  end
end

RSpec.describe Kannuki::DeadlockError do
  it 'inherits from Kannuki::Error' do
    expect(described_class.superclass).to eq Kannuki::Error
  end

  describe '#initialize' do
    it 'stores lock_key' do
      error = described_class.new('my_lock')

      expect(error.lock_key).to eq 'my_lock'
    end

    it 'formats message' do
      error = described_class.new('my_lock')

      expect(error.message).to eq 'Deadlock detected while acquiring lock: my_lock'
    end
  end
end

RSpec.describe Kannuki::NestedLockError do
  it 'inherits from Kannuki::Error' do
    expect(described_class.superclass).to eq Kannuki::Error
  end

  describe '#initialize' do
    it 'formats message with both lock names' do
      error = described_class.new('outer', 'inner')

      expect(error.message).to include('outer')
      expect(error.message).to include('inner')
      expect(error.message).to include('MySQL limitation')
    end
  end
end
