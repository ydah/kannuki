# frozen_string_literal: true

RSpec.describe Kannuki::Testing do
  before do
    described_class.disable!
    Kannuki.reset_configuration!
  end

  after do
    described_class.clear!
  end

  describe '.enable!' do
    it 'enables test mode in configuration' do
      described_class.enable!

      expect(Kannuki.configuration.test_mode).to be true
    end
  end

  describe '.disable!' do
    it 'disables test mode in configuration' do
      described_class.enable!
      described_class.disable!

      expect(Kannuki.configuration.test_mode).to be false
    end
  end

  describe '.test_mode?' do
    it 'returns false by default' do
      expect(described_class.test_mode?).to be false
    end

    it 'returns true when enabled' do
      described_class.enable!

      expect(described_class.test_mode?).to be true
    end
  end

  describe '.simulate_lock_held' do
    before { described_class.enable! }

    it 'marks a lock as held' do
      described_class.simulate_lock_held('my_lock')

      expect(described_class.lock_held?('my_lock')).to be true
    end
  end

  describe '.release_simulated_lock' do
    before { described_class.enable! }

    it 'releases a simulated lock' do
      described_class.simulate_lock_held('my_lock')
      described_class.release_simulated_lock('my_lock')

      expect(described_class.lock_held?('my_lock')).to be false
    end
  end

  describe '.lock_held?' do
    before { described_class.enable! }

    it 'returns false for non-held lock' do
      expect(described_class.lock_held?('unknown')).to be false
    end

    it 'returns true for held lock' do
      described_class.simulate_lock_held('held_lock')

      expect(described_class.lock_held?('held_lock')).to be true
    end
  end

  describe '.held_locks' do
    before { described_class.enable! }

    it 'returns empty array when no locks held' do
      expect(described_class.held_locks).to eq []
    end

    it 'returns list of held locks' do
      described_class.simulate_lock_held('lock1')
      described_class.simulate_lock_held('lock2')

      expect(described_class.held_locks).to contain_exactly('lock1', 'lock2')
    end
  end

  describe '.clear!' do
    before { described_class.enable! }

    it 'clears all simulated locks' do
      described_class.simulate_lock_held('lock1')
      described_class.simulate_lock_held('lock2')
      described_class.clear!

      expect(described_class.held_locks).to be_empty
    end
  end
end
