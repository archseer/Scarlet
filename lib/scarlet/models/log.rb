require 'thread'
require 'scarlet/core_ext/literal'
require 'scarlet/models/model_base'

# basically stores the entire Event inside the DB.
# port of Defusal's system
class Scarlet
  class Log < ModelBase
    field :nick,     type: String,  default: nil
    field :channel,  type: String,  default: nil
    field :command,  type: Literal, default: nil
    field :target,   type: String,  default: nil
    field :message,  type: String,  default: nil

    def self.repo_config
      {
        memory: true
      }
    end

    def self.pool
      @pool ||= LogPool.new
    end

    # @param [Hash] data
    def self.log(data)
      pool.next.update(data).tap { |l| l.created_at = l.updated_at }
    end

    # Create a new log entry from an event.
    #
    # @param [Event] event The event we want to log.
    def self.write event
      return if !event.sender.nick || (event.sender.nick == "Global" or event.sender.nick =~ /Serv$/)
      log(
        nick: event.sender.nick,
        message: event.params.join(" "),
        channel: event.channel,
        command: event.command.upcase,
        target: event.target
      )
    end

    #scope :in_channel, lambda { where(:channel.ne => "") } # ne -> not equals
    #scope :nick, lambda {|nick| where(:nick => nick) }
    #scope :channel, lambda {|channel| where(:channel => channel) }
    #scope :join, lambda { where(:command => 'JOIN') }
    #scope :privmsg, lambda { where(:command => 'PRIVMSG') }
    #scope :created_at, lambda {|created_at| where(:created_at => created_at) }
    #scope :message, lambda {|msg| where(:message => msg) }
  end

  #
  class LogPool
    def initialize
      @index = 0
      @log_m = Mutex.new
      @pool ||= Array.new(100) do
        Log.create
      end
    end

    def next
      obj = nil
      @log_m.synchronize do
        obj = @pool[@index]
        @index = (@index + 1) % @pool.size
      end
      obj
    end
  end
end
