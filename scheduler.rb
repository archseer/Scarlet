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
require 'rufus/scheduler'

module Rufus::Scheduler
  class EmScheduler
    def trigger_job(blocking, &block)
      EM.next_tick { block.call }
    end
  end
end

class Scheduler
  class << self
    @@instances = []
    @@queue = []

    EM.next_tick do
      @@scheduler = Rufus::Scheduler::EmScheduler.start_new
      @@queue.each do |name, args, block|
        @@scheduler.send(name, *args, &block)
        @@queue = []
      end
      @@instances.each do |scheduler|
        scheduler.queue.each do |name, args, block|
          scheduler.jobs << @@scheduler.send(name, *args, &block)
        end
        scheduler.queue = []
      end
    end

    def unschedule_by_tag(tags)
      find_by_tag(tags).each {|job| job.unschedule }
    end

    def method_missing(name, *args, &block)
      #puts "[Scheduler] #{name}, #{args.join ', '}"
      if [:in, :at, :every, :cron].include? name
        if defined? @@scheduler
          @@scheduler.send(name, *args, &block)
        else
          @@queue << [name, args, block]
        end
      else
        @@scheduler.send(name, *args, &block)
      end
    end
  end

  attr_accessor :queue, :jobs

  def initialize
    @@instances << self
    @queue = []
    @jobs = []
  end

  def unschedule_by_tag(tags)
    self.class.unschedule_by_tag(tags)
  end

  def remove_all
    @jobs.each do |job|
      job.unschedule
    end
    @@instances.delete self
  end

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