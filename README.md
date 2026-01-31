<h1 align="center">Kannuki</h1>
<p align="center">
  Advisory locking for ActiveRecord with modern Rails conventions.
</p>

<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#basic-usage">Basic Usage</a> •
  <a href="#model-extension">Model Extension</a> •
  <a href="#activejob-integration">ActiveJob</a> •
  <a href="#configuration">Configuration</a> •
  <a href="docs/guide.md">User Guide</a>
</p>

Kannuki provides database-agnostic advisory locking for ActiveRecord with support for PostgreSQL and MySQL, offering blocking/non-blocking strategies, instrumentation, and ActiveJob integration.

## Installation

Add to your Gemfile:

```ruby
gem 'kannuki'
```

Then run:

```bash
bundle install
```

Generate an initializer (optional):

```bash
rails generate kannuki:install
```

## Basic Usage

### Simple Lock

```ruby
Kannuki.with_lock("my_critical_section") do
  # Exclusive execution
end
```

### With Timeout

```ruby
Kannuki.with_lock("process_order", timeout: 10) do
  # Returns false if lock not acquired within 10 seconds
end
```

### Non-blocking (Try Lock)

```ruby
result = Kannuki.try_lock("quick_check") do
  perform_quick_operation
end
puts "Lock was not available" if result == false
```

### Raise on Failure

```ruby
Kannuki.lock!("must_succeed") do
  critical_operation
end
# => raises Kannuki::LockNotAcquiredError if lock unavailable
```

## Model Extension

```ruby
class Order < ApplicationRecord
  kannuki :number_generation, scope: :organization_id
end
```

Usage:

```ruby
order.with_number_generation_lock do
  order.number = organization.orders.maximum(:number).to_i + 1
  order.save!
end

# Non-blocking
order.try_number_generation_lock { ... }

# Raise on failure
order.number_generation_lock! { ... }

# Check if locked
order.number_generation_locked?
```

Ad-hoc locking:

```ruby
order.with_lock("custom_operation") do
  # Lock key: "orders/123/custom_operation"
end
```

## ActiveJob Integration

### Prevent Concurrent Execution

```ruby
class HeavyImportJob < ApplicationJob
  with_lock :import, key: -> { arguments.first }
  
  def perform(import_id)
    # Exclusive execution per import_id
  end
end
```

### Skip Duplicate Jobs

```ruby
class DataSyncJob < ApplicationJob
  unique_by_lock on_conflict: :skip
  
  def perform(resource_type, resource_id)
    # Only one job with same arguments runs at a time
  end
end
```

## Configuration

```ruby
# config/initializers/kannuki.rb
Kannuki.configure do |config|
  config.default_timeout = 30
  config.default_strategy = :blocking
  config.key_prefix = "myapp"
  config.enable_instrumentation = Rails.env.production?
  config.retry_attempts = 3
  config.retry_interval = 0.5
  config.retry_backoff = :exponential
end
```

### Strategies

| Strategy | Behavior |
|----------|----------|
| `:blocking` | Waits until lock available or timeout (default) |
| `:non_blocking` | Returns immediately if unavailable |
| `:retry` | Retries with configurable backoff |

```ruby
Kannuki.with_lock("op", strategy: :retry, retry_attempts: 5) { ... }
```

## Instrumentation

Kannuki emits ActiveSupport::Notifications events:

- `acquired.kannuki`
- `released.kannuki`
- `failed.kannuki`
- `timeout.kannuki`
- `waiting.kannuki`

```ruby
ActiveSupport::Notifications.subscribe(/\.kannuki$/) do |name, start, finish, id, payload|
  duration = (finish - start) * 1000
  Rails.logger.info "[Kannuki] #{name}: #{payload[:lock_key]} (#{duration.round(2)}ms)"
end
```

## Testing

```ruby
RSpec.configure do |config|
  config.before { Kannuki::Testing.enable! }
  config.after { Kannuki::Testing.clear! }
end

# In tests
Kannuki::Testing.simulate_lock_held("my_lock")
result = Kannuki.try_lock("my_lock") { "success" }
expect(result).to be false
```

## Database Support

### PostgreSQL

| Feature | Supported |
|---------|-----------|
| Session-level locks | Yes |
| Transaction-level locks | Yes |
| Shared locks | Yes |

### MySQL

| Feature | Supported |
|---------|-----------|
| Session-level locks | Yes |
| Transaction-level locks | No |
| Shared locks | No |

## Requirements

- Ruby >= 3.1
- Rails >= 7.0
- PostgreSQL >= 12 or MySQL >= 8.0

## Development

```bash
bundle install
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ydah/kannuki.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
