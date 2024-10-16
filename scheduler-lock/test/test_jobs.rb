# Job that prevents the job being enqueued if already enqueued/running.
class LonelyJob
  extend Resque::Plugins::LockTimeout
  @queue = :test
  @loner = true

  def self.perform
    $success += 1
    sleep 0.2
  end

  def self.loner_enqueue_failed(*args)
    $enqueue_failed += 1
  end
end

# Exclusive job (only one queued/running) with a timeout.
class LonelyTimeoutJob
  extend Resque::Plugins::LockTimeout
  @queue = :test
  @loner = true
  @lock_timeout = 60

  def self.perform
    $success += 1
    sleep 0.2
  end

  def self.loner_enqueue_failed(*args)
    $enqueue_failed += 1
  end
end

# This job won't complete before it's timeout
class LonelyTimeoutExpiringJob
  extend Resque::Plugins::LockTimeout
  @queue = :test
  @loner = true
  @lock_timeout = 1

  def self.perform
    sleep 2
  end
end
