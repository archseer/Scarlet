=begin
<Defusal> if you need timers, use the EM-based core of Rufus-Sheduler, its great
<Defusal> i wrapped it for my modules, so each module has its own timers which are all destroyed on unload
<Defusal> http://pastie.org/3305750
<Defusal> so in unload, i do: mod.scheduler.remove_all if mod.respond_to? :scheduler
<Defusal> and well, i load my modules very differently, but basically
<Defusal> base.instance_variable_set :@scheduler, Scheduler.new
<Defusal> and then i make a attr_reader for it on both the class and instance level
-----
<Defusal> you create a new instance per module
<Defusal> and then use the methods to add and remove timers
<Defusal> method_missing delegates everything that is not defined in the file to the Rufus::Scheduler instance
<Defusal> its a proxy class
<Defusal> it tracks scheduled items per instance you create, so that you can remove them all when unloading a module
<Speeda>  scheduler = Scheduler.new
<Speeda>  scheduler.at ...
<Defusal> then you call scheduler.remove_all when unloading the module
<Defusal> and all its timers will be destroyed
=end
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