# frozen_string_literal: true

module Kannuki
  class Railtie < Rails::Railtie
    initializer 'kannuki.configure_rails_initialization' do
      ActiveSupport.on_load(:active_record) do
        include Kannuki::ModelExtension
      end

      ActiveSupport.on_load(:active_job) do
        include Kannuki::ActiveJobExtension
      end
    end

    initializer 'kannuki.log_subscriber' do
      if Kannuki.configuration.enable_instrumentation
        ActiveSupport::Notifications.subscribe(/\.kannuki$/) do |name, start, finish, _id, payload|
          event = name.sub('.kannuki', '')
          duration = ((finish - start) * 1000).round(2)

          message = case event
                    when 'acquired'
                      "Acquired lock: #{payload[:lock_key]} (#{duration}ms)"
                    when 'released'
                      "Released lock: #{payload[:lock_key]} (#{duration}ms)"
                    when 'failed'
                      "Failed to acquire lock: #{payload[:lock_key]} (reason: #{payload[:reason]})"
                    when 'timeout'
                      "Lock timeout: #{payload[:lock_key]} (timeout: #{payload[:timeout]}s)"
                    when 'waiting'
                      "Waiting for lock: #{payload[:lock_key]}"
                    end

          Kannuki.configuration.logger.debug("[Kannuki] #{message}") if message
        end
      end
    end
  end
end
