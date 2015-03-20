#=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
# scheduler.rb - Rufus scheduler proxy
#------------------------------------------------
# A proxy used to create a scheduler instance inside each
# module that needs it.
# => Usage
# Create an instance of scheduler (scheduler = Scheduler.new)
# Create an access method for it.
# Use as usual (http://rufus.rubyforge.org/rufus-scheduler/)
# Call scheduler.remove_all when unloading the module
#================================================
require 'rufus-scheduler'

# A proxy class used to create individual scheduler instances for each class
# that needs it.
class Scheduler
  class << self
    @@instances = []

    EM.next_tick do
      @@scheduler = Rufus::Scheduler.new
      @@instances.each do |scheduler|
        scheduler.queue.each do |name, args, block|
          scheduler.jobs << @@scheduler.send(name, *args, &block)
        end
        scheduler.queue = []
      end
    end
  end

  attr_accessor :queue, :jobs

  # Creates a new instance of the scheduler.
  def initialize
    @@instances << self
    @queue = []
    @jobs = []
  end

  # Remove all jobs from the scheduler.
  def remove_all
    @jobs.each do |job|
      job.unschedule
    end
    @@instances.delete self
  end

  # Delegates methods to Rufus Scheduler.
  def method_missing(name, *args, &block)
    if [:in, :at, :every, :cron].include? name
      if defined? @@scheduler
        ret = @@scheduler.send(name, *args, &block)
        @jobs << ret
        ret
      else
        @queue << [name, args, block]
      end
    else
      @@scheduler.send(name, *args, &block)
    end
  end
end
