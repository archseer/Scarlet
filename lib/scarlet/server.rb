require 'active_support/configurable'
require 'eventmachine'
require 'rufus-scheduler'
require 'scarlet/logger'
require 'scarlet/models/log'
require 'scarlet/connection'
require 'scarlet/event'
require 'scarlet/parser'
require 'scarlet/models/log'
require 'scarlet/fmt'

class Scarlet
  # This class is the meat of the bot, encapsulating the connection and
  # various event listeners that respond to server messages, as well as
  # a list of users and channels the bot is connected to. All the magic
  # happens in this class.
  class Server
    include ActiveSupport::Configurable
    include Scarlet::Loggable

    attr_reader :channels
    attr_reader :scheduler
    attr_reader :users
    attr_accessor :started_at
    attr_accessor :cap_extensions
    attr_accessor :current_nick
    attr_accessor :extensions
    attr_accessor :ircd
    attr_accessor :modes
    attr_accessor :parser
    attr_accessor :plugins
    attr_accessor :sasl
    attr_accessor :sasl_mechanisms
    attr_accessor :state
    attr_accessor :logs
    attr_accessor :vHost

    # Initializes a new abstracted connection instance to an IRC server.
    # The actual EM connection instance gets set to +self.connection+.
    #
    # @param [Hash] cfg A hash with configuration keys and values.
    def initialize cfg
      config.log_buffer_size = 256
      config.delay_join = true
      config.merge! cfg.symbolize_keys
      @current_nick = config.nick
      config.control_char ||= Scarlet.config.control_char
      config.buffer_rate ||= 1
      config.freeze

      @scheduler = Rufus::Scheduler.new
      @channels  = ServerChannels.new # channels
      @users     = Users.new          # users (seen) on the server
      @state     = :connecting
      @logs      = LogBuffer.new(config.log_buffer_size)
      @reconnects = 0
      reset_vars
      connect!
    end

    def buffer_loop
      b = @buffer
      EM.add_timer config.buffer_rate do
        b.pop do |d|
          @connection.send_data d if @connection
          # make sure we aren't currently disconnecting and that the buffer we have, is the same as the active one.
          if @state != :disconnecting && b == @buffer
            buffer_loop
          end
        end
      end
    end

    # Resets the variables to their default values. This gets triggered when the
    # instance gets created as well as any time the bot reconnects to the server.
    def reset_vars
      @sasl_mechanisms = [Scarlet::SASL::DH_Blowfish, Scarlet::SASL::Plain]
      @sasl = nil

      @channels.clear
      @users.clear
      @buffer.push '' if @buffer # to avoid locking the buffer_loop while waiting on a object
      @buffer = EM::Queue.new
      @modes           = []     # bot account's modes (ix,..)
      @extensions      = {}     # what the server-side supports (PROTOCTL)
      @cap_extensions  = {}     # CAPability extensions (CAP REQ)
      @vHost           = nil    # vHost/cloak
      buffer_loop
    end

    def send_sasl
      if @sasl = @sasl_mechanisms.shift
        logger.info "[SASL] Authentication attempt with #{@sasl.mechanism_name}"
        send "AUTHENTICATE #{@sasl.mechanism_name}"
      else
        send 'CAP END'
      end
    end

    # An alias for config.server_name.
    def name
      config.server_name
    end

    # Connects the bot to the network.
    # @note This method does nothing, once a connection exists. Use reconnect instead.
    def connect!
      return if @connection
      @connection = EM.connect(config.address, config.port, Connection, self)
    end

    def reconnect
      disconnect unless @state == :disconnecting
      reset_vars
      @reconnects += 1
      logger.info "Waiting #{2**@reconnects} seconds to reconnect..."
      EM.add_timer(2 ** @reconnects) do
        @state = :connecting
        begin
          @connection.reconnect(config.address, config.port)
          @connection.post_init
          @reconnects = 0
        rescue => ex
          logger.error ex.message
          reconnect
        end
      end
    end

    # Disconnects the bot from the network. It sends a +QUIT+ message to the server,
    # and closes the connection to the server.
    def disconnect
      send "QUIT :#{Scarlet.config.quit}"
      @state = :disconnecting
      @connection.close_connection(true)
    end

    # This method gets called from the connection instance once the connection to
    # the server was closed. It checks whether we actually wanted to disconnect, or
    # whether the bot lost connection from the server. If the connection was
    # unintentional, it starts the reconnection process.
    def unbind
      reset_vars

      return unless @state == :disconnecting
      logger.error "Connection to server lost. Reconnecting..."
      reconnect
    end

    # Sends the data over to the server.
    #
    # @param [String] data The message to be sent.
    def send data
      @connection.send_data data
    end

    # Pushes data to the internal buffer for sending over a set period
    #
    # @param [String] data The message to be sent.
    def throttle_send data
      @buffer << data
    end

    # Parses the recieved line from the server into an event, then it logs the
    # event and distributes the event over to handlers.
    #
    # @param [String] line The line that was recieved from the server.
    def receive_line line
      parsed_line = Parser.parse_line line
      event = Event.new(self, parsed_line[:prefix], parsed_line[:command],
                        parsed_line[:target], parsed_line[:params])
      logs.write(event)
      @plugins.each do |plug|
        plug.handle event
      end
    end

    # Write down the command to the log (in our case a MongoDB database), ignoring
    # any message sent to +*Serv+ bots.
    # @param [Symbol] command The type of the command we recieved.
    # @param [String] message The message we want to log for the command.
    # @param [String] target Whom the command has targeted.
    def write_log command, message, target
      return if target =~ /Serv$/ # if we PM a bot, i.e. for logging in, that shouldn't be logged.

      channel = target.starts_with?("#") ? target : ''
      logs.log(nick: @current_nick, message: message,
               command: command.upcase, target: target, channel: channel)
    end
  end
end
