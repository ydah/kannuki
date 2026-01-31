# frozen_string_literal: true

require 'active_record'
require 'active_support'
require 'active_support/concern'

require_relative 'kannuki/version'
require_relative 'kannuki/errors'
require_relative 'kannuki/configuration'
require_relative 'kannuki/lock_key'
require_relative 'kannuki/result'
require_relative 'kannuki/instrumentation'
require_relative 'kannuki/adapters'
require_relative 'kannuki/strategies'
require_relative 'kannuki/lock_manager'
require_relative 'kannuki/model_extension'
require_relative 'kannuki/active_job_extension'
require_relative 'kannuki/testing'
require_relative 'kannuki/railtie' if defined?(Rails::Railtie)

module Kannuki
  class << self
    delegate :with_lock, :try_lock, :lock!, :locked?, :current_locks, :holding_lock?, to: LockManager
  end
end
