# Kannuki User Guide

Kannuki is a gem that provides advisory locking for Rails applications. It enables exclusive control across multiple processes and servers using database-level locking.

## Table of Contents

1. [Installation](#installation)
2. [Basic Usage](#basic-usage)
3. [Use Cases](#use-cases)
4. [Configuration](#configuration)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

## Installation

Add to your Gemfile:

```ruby
gem 'kannuki'
```

Run:

```bash
$ bundle install
```

Generate initializer (optional):

```bash
$ rails generate kannuki:install
```

## Basic Usage

### Simple Lock

```ruby
Kannuki.with_lock("my_operation") do
  # This block runs exclusively
end
```

### Non-blocking Lock

```ruby
result = Kannuki.try_lock("my_operation") do
  # Runs only if lock is immediately available
  "success"
end

if result == false
  puts "Lock was not available"
end
```

### Lock with Exception on Failure

```ruby
Kannuki.lock!("critical_operation") do
  # Raises Kannuki::LockNotAcquiredError if lock unavailable
end
```

## Use Cases

### 1. Preventing Duplicate Order Processing

Problem: Multiple workers might process the same order simultaneously.

Solution:

```ruby
class OrderProcessor
  def process(order_id)
    Kannuki.with_lock("order_processing/#{order_id}") do
      order = Order.find(order_id)
      return if order.processed?

      order.process!
      order.update!(processed: true)
    end
  end
end
```

### 2. Sequential Number Generation

Problem: Auto-incrementing custom numbers (invoice numbers, ticket numbers) can collide.

Solution:

```ruby
class Invoice < ApplicationRecord
  kannuki :number_generation, scope: :company_id
end

class InvoiceService
  def create_invoice(company, params)
    invoice = company.invoices.build(params)

    invoice.with_number_generation_lock do
      last_number = company.invoices.maximum(:invoice_number) || 0
      invoice.invoice_number = last_number + 1
      invoice.save!
    end

    invoice
  end
end
```

### 3. Preventing Duplicate Background Jobs

Problem: The same job might be enqueued multiple times and run concurrently.

Solution:

```ruby
class DataSyncJob < ApplicationJob
  unique_by_lock on_conflict: :skip

  def perform(resource_type, resource_id)
    # Only one job with same arguments runs at a time
    # Duplicate jobs are silently skipped
  end
end
```

### 4. Rate Limiting External API Calls

Problem: External API has rate limits; concurrent calls might exceed them.

Solution:

```ruby
class ExternalApiClient
  def fetch_data(endpoint)
    Kannuki.with_lock("api/#{endpoint}", timeout: 30) do
      # Only one request to this endpoint at a time
      HTTP.get("https://api.example.com/#{endpoint}")
    end
  end
end
```

### 5. Exclusive Resource Access per User

Problem: User should only have one active session performing a specific operation.

Solution:

```ruby
class ReportGenerator
  def generate(user_id, report_type)
    result = Kannuki.try_lock("reports/#{user_id}/#{report_type}") do
      # Generate report
      Report.create!(user_id: user_id, type: report_type, data: build_report)
    end

    if result == false
      raise "Report generation already in progress"
    end

    result
  end
end
```

### 6. Database Migration Safety

Problem: Running migrations on multiple servers simultaneously can cause issues.

Solution:

```ruby
class SafeMigrationJob < ApplicationJob
  with_lock :migration, key: -> { "db_migration" }

  def perform(migration_name)
    # Only one server runs migrations at a time
    ActiveRecord::Migration.run(migration_name)
  end
end
```

### 7. Singleton Scheduler

Problem: Scheduled task should only run on one server in a cluster.

Solution:

```ruby
class SchedulerJob < ApplicationJob
  def perform
    result = Kannuki.try_lock("scheduler/hourly_tasks") do
      HourlyTasks.each(&:run)
    end

    # If result is false, another server is handling it
    Rails.logger.info("Scheduler skipped - another instance running") if result == false
  end
end
```

### 8. Inventory Management

Problem: Concurrent purchases might oversell limited inventory.

Solution:

```ruby
class PurchaseService
  def purchase(product_id, quantity, user)
    Kannuki.lock!("inventory/#{product_id}", timeout: 10) do
      product = Product.find(product_id)

      if product.stock >= quantity
        product.decrement!(:stock, quantity)
        Order.create!(product: product, quantity: quantity, user: user)
      else
        raise InsufficientStockError
      end
    end
  rescue Kannuki::LockNotAcquiredError
    raise "Product is currently being purchased by another user. Please try again."
  end
end
```

## Configuration

```ruby
# config/initializers/kannuki.rb
Kannuki.configure do |config|
  # Default timeout in seconds (nil = wait indefinitely)
  config.default_timeout = 30

  # Default strategy (:blocking, :non_blocking, :retry)
  config.default_strategy = :blocking

  # Prefix for all lock keys (recommended for multi-app environments)
  config.key_prefix = "myapp"

  # Enable instrumentation for monitoring
  config.enable_instrumentation = Rails.env.production?

  # Retry strategy settings
  config.retry_attempts = 3
  config.retry_interval = 0.5
  config.retry_backoff = :exponential  # :exponential, :linear, :constant
end
```

### Lock Strategies

| Strategy | Behavior | Use When |
|----------|----------|----------|
| `:blocking` | Waits until lock available or timeout | Default, most operations |
| `:non_blocking` | Returns immediately if unavailable | Quick checks, optional operations |
| `:retry` | Retries with backoff | Transient contention expected |

```ruby
# Blocking (default)
Kannuki.with_lock("op", strategy: :blocking, timeout: 30) { ... }

# Non-blocking
Kannuki.with_lock("op", strategy: :non_blocking) { ... }
# or
Kannuki.try_lock("op") { ... }

# Retry with custom settings
Kannuki.with_lock("op", strategy: :retry, retry_attempts: 5, retry_interval: 0.2) { ... }
```

## Testing

### Setup

```ruby
# spec/spec_helper.rb or spec/rails_helper.rb
RSpec.configure do |config|
  config.before do
    Kannuki::Testing.enable!
  end

config.after do
    Kannuki::Testing.clear!
  end
end
```

### Simulating Held Locks

```ruby
RSpec.describe OrderProcessor do
  it "waits when order is being processed" do
    # Simulate another process holding the lock
    Kannuki::Testing.simulate_lock_held("order_processing/123")

    result = Kannuki.try_lock("order_processing/123") { "processed" }

    expect(result).to be false
  end

  it "processes order when lock is available" do
    result = Kannuki.with_lock("order_processing/123") { "processed" }

    expect(result).to eq "processed"
  end
end
```

### Using RSpec Helpers

```ruby
RSpec.describe MyService do
  extend Kannuki::Testing::RSpecHelpers

  with_kannuki_test_mode  # Automatically enables/clears test mode

  it "acquires lock" do
    # Test mode is automatically enabled
  end
end
```

## Troubleshooting

### Lock Not Being Released

Symptom: Locks remain held after process crashes.

Cause: Process terminated without releasing session lock.

Solution: Session locks are automatically released when the database connection closes. Ensure your connection pool is properly configured. For critical operations, consider using transaction-scoped locks:

```ruby
Kannuki.with_lock("op", transaction: true) do
  # Lock released when transaction ends
end
```

### Timeout Errors

Symptom: `Kannuki::LockNotAcquiredError` or `false` returns frequently.

Cause: High contention on the same lock.

Solutions:
1. Increase timeout: `timeout: 60`
2. Use more granular lock keys: `"orders/#{order_id}"` instead of `"orders"`
3. Use retry strategy: `strategy: :retry`

### MySQL Nested Lock Warning

Symptom: Nested locks fail on MySQL.

Cause: MySQL's `GET_LOCK` only allows one lock per connection.

Solution: Restructure code to avoid nested locks, or use a single composite lock key.

### Performance Concerns

Best Practices:
1. Keep locked sections short
2. Use specific lock keys to reduce contention
3. Set appropriate timeouts
4. Monitor lock metrics via instrumentation

```ruby
# Monitor lock events
ActiveSupport::Notifications.subscribe(/\.kannuki$/) do |name, start, finish, id, payload|
  duration_ms = (finish - start) * 1000
  StatsD.timing("kannuki.#{name.sub('.kannuki', '')}", duration_ms)
end
```
