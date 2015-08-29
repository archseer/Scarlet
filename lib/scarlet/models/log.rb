require 'thread'
require 'scarlet/core_ext/literal'
require 'scarlet/models/model_base'
require 'active_support/core_ext/module/delegation'

# basically stores the entire Event inside the DB.
# port of Defusal's system
class Scarlet
  class Log < ModelBase
    field_setting allow_nil: true, default: proc { '' } do
      field :nick,     type: String
      field :channel,  type: String
      field :command,  type: Literal
      field :target,   type: String
      field :message,  type: String
    end

    attr_accessor :repository
  end

  # Also known as the repository class for Logs, unlike other models which
  # have their repository code merged into their singleton class, Logs
  # have a dedicated repository class.
  class Logs
    include Moon::Record::ClassMethods

    def repo_config
      { memory: true }
    end

    def create(*args, &block)
      record = super(*args, &block)
      record.repository = repository
      record
    end

    def model
      Log
    end

    define_method(:in_channel) { where_with_block { |d| d[:channel].present? } }
    define_method(:nick) { |nick| where(nick: nick) }
    define_method(:channel) { |channel| where(channel: channel) }
    define_method(:join) { where(command: 'JOIN') }
    define_method(:privmsg) { where(command: 'PRIVMSG') }
    define_method(:created_at) { |time| where(created_at: time) }
    define_method(:message) { |msg| where(message: msg) }
  end

  # A ring buffer for logs
  class LogBuffer
    # @param [Integer] size  the buffer size
    def initialize(size = 256)
      @index = 0
      @log_m = Mutex.new
      @repository = Logs.new
      @buffer ||= Array.new(size) do
        @repository.create
      end
    end

    # @return [Log]
    def next_available
      @log_m.synchronize do
        yield @buffer[@index]
        @index = (@index + 1) % @buffer.size
      end
    end

    # @param [Hash] data
    def log(data)
      next_available do |l|
        l.update(data).tap { |l| l.created_at = l.updated_at }
      end
    end

    # Create a new log entry from an event.
    #
    # @param [Event] event The event we want to log.
    def write event
      return if !event.sender.nick || (event.sender.nick == "Global" or event.sender.nick =~ /Serv$/)
      log(
        nick: event.sender.nick,
        message: event.params.join(" "),
        channel: event.channel,
        command: event.command.upcase,
        target: event.target
      )
    end

    delegate :in_channel, :nick, :channel, :join, :privmsg, :created_at, :message, to: :@repository
  end
end
