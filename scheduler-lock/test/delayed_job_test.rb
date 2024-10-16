require File.dirname(__FILE__) + "/test_helper"

require "debug"
require "resque-scheduler"

def scheduler_version_compare(version)
  Gem::Requirement.create(version).satisfied_by?(Gem::Version.create(Resque::Scheduler::VERSION))
end

class LockTest < Minitest::Test
  def setup
    $success = $lock_failed = $lock_expired = $enqueue_failed = 0
    Resque::Scheduler.quiet = true
    Resque.redis.redis.flushall
    @worker = Resque::Worker.new(:test)
  end

  def test_delayed_item_enqueue
    t = Time.now + 60

    # Resque::Scheduler.expects(:enqueue_next_item).never

    # create 90 jobs
    90.times { Resque.enqueue_at(t, LonelyJob) }
    assert_equal(90, Resque.delayed_timestamp_size(t))

    Resque::Scheduler.enqueue_delayed_items_for_timestamp(t)
    assert_equal(0, Resque.delayed_timestamp_size(t))

    # assert that the active queue has the lonely job
    if scheduler_version_compare("< 4.9")
      assert_equal(1, Resque.size(Resque.queue_from_class(LonelyJob)))
    elsif Resque::Scheduler::VERSION.end_with?("-ibotta")
      assert_equal(1, Resque.size(Resque.queue_from_class(LonelyJob)))
    else
      # this is asserting that > 4.9 "fails" without the patch
      assert_equal(0, Resque.size(Resque.queue_from_class(LonelyJob)))
    end
  end
end

if Resque::Scheduler::VERSION.end_with?("-ibotta")
  class LockBatchOffTest < Minitest::Test
    def setup
      @batch_enabled = Resque::Scheduler.enable_delayed_requeue_batches
      @batch_size = Resque::Scheduler.delayed_requeue_batch_size

      $success = $lock_failed = $lock_expired = $enqueue_failed = 0
      Resque::Scheduler.quiet = true
      Resque.redis.redis.flushall
      @worker = Resque::Worker.new(:test)

      Resque::Scheduler.enable_delayed_requeue_batches = false
      Resque::Scheduler.delayed_requeue_batch_size = 1
    end

    def teardown
      Resque::Scheduler.enable_delayed_requeue_batches = @batch_enabled
      Resque::Scheduler.delayed_requeue_batch_size = @batch_size
    end

    def test_delayed_item_enqueue
      t = Time.now + 60

      # Resque::Scheduler.expects(:enqueue_next_item).never

      # create 90 jobs
      90.times { Resque.enqueue_at(t, LonelyJob) }
      assert_equal(90, Resque.delayed_timestamp_size(t))

      Resque::Scheduler.enqueue_delayed_items_for_timestamp(t)
      assert_equal(0, Resque.delayed_timestamp_size(t))

      # assert that the active queue has the lonely job
      if scheduler_version_compare("< 4.9")
        assert_equal(1, Resque.size(Resque.queue_from_class(LonelyJob)))
      elsif Resque::Scheduler::VERSION.end_with?("-ibotta")
        # should act like before
        assert_equal(1, Resque.size(Resque.queue_from_class(LonelyJob)))
      else
        # this is asserting that > 4.9 "fails" without the patch
        assert_equal(0, Resque.size(Resque.queue_from_class(LonelyJob)))
      end
    end
  end

  class LockBatchOnTest < Minitest::Test
    def setup
      @batch_enabled = Resque::Scheduler.enable_delayed_requeue_batches
      @batch_size = Resque::Scheduler.delayed_requeue_batch_size

      $success = $lock_failed = $lock_expired = $enqueue_failed = 0
      Resque::Scheduler.quiet = true
      Resque.redis.redis.flushall
      @worker = Resque::Worker.new(:test)

      Resque::Scheduler.enable_delayed_requeue_batches = true
      Resque::Scheduler.delayed_requeue_batch_size = 100
    end

    def teardown
      Resque::Scheduler.enable_delayed_requeue_batches = @batch_enabled
      Resque::Scheduler.delayed_requeue_batch_size = @batch_size
    end

    def test_delayed_item_enqueue
      t = Time.now + 60

      # Resque::Scheduler.expects(:enqueue_next_item).never

      # create 90 jobs
      90.times { Resque.enqueue_at(t, LonelyJob) }
      assert_equal(90, Resque.delayed_timestamp_size(t))

      Resque::Scheduler.enqueue_delayed_items_for_timestamp(t)
      assert_equal(0, Resque.delayed_timestamp_size(t))

      # assert that the active queue has the lonely job
      if scheduler_version_compare("< 4.9")
        assert_equal(1, Resque.size(Resque.queue_from_class(LonelyJob)))
      elsif Resque::Scheduler::VERSION.end_with?("-ibotta")
        assert_equal(0, Resque.size(Resque.queue_from_class(LonelyJob)))
      else
        # this is asserting that > 4.9 "fails" without the patch
        assert_equal(0, Resque.size(Resque.queue_from_class(LonelyJob)))
      end
    end
  end

end
