require 'scarlet/logger'

# A connection instance that gets used by EM to send and recieve messages.
# Provides basic IRC initialization and automated timeout checking.
class Scarlet::Connection < EM::Connection
  include Scarlet::Loggable
  include EventMachine::Protocols::LineText2

  # Initialize a new connection.
  # @note Never make a new instance directly, but by using EM.connect.
  # @param [Server] server Our server instance to give the messages to.
  def initialize server
    @server = server
  end

  # Once our connection is open, send the +NICK+, +USER+ and +CAP+ message,
  # to start the handshake.
  def connection_completed
    start_tls if @server.config.ssl
    handshake
    reset_check_connection_timer
  end

  def ssl_handshake_completed
    Scarlet.logger.info ">> TLS/SSL is ENABLED for #{@server.name}".green
  end

  def handshake
    send_data "CAP LS" # CAP extension http://ircv3.atheme.org/ (freenode)
    send_data "PASS #{@server.config.password}" if @server.config.password
    send_data "NICK #{@server.current_nick}"
    send_data "USER #{Scarlet.config.host} * * :#{Scarlet.config.name}"
  end

  # Gets a recieved message and gives it to +Server+.
  # @param [String] line The line that was recieved from the server.
  def receive_line line
    logger.debug " > #{line}"
    reset_check_connection_timer
    @server.receive_line line
  end

  # Sends data back to the server, using the carriage return as an escape symbol
  # (as per IRC specs).
  # @param [String, #to_s] data The data to be sent to server.
  def send_data data
    logger.debug " < #{data}"
    super "#{data}\r\n"
  end

  # Closes the connection to server and triggers the +@server.unbind+ method.
  def unbind
    @check_connection_timer.cancel if @check_connection_timer
    @server.unbind
  end

  private
  def check_connection
    send_data "PING #{@server.config.address}"
    @check_connection_timer = EM::Timer.new 30, method(:timeout)
  end

  # This method gets called when the ping response doesn't return in the alloted time.
  # We assume the bot has lost connection to the server, so we send a QUIT ping timeout
  # message to the server and forcefully close the connection, which then triggers the
  # reconnect mechanism.
  def timeout
    send_data "QUIT :Ping timeout"
    close_connection_after_writing
  end

  # Resets the timer that is checking for new messages. If this timer ever gets to zero,
  # it triggers +timeout+ and forces the bot to reconnect.
  def reset_check_connection_timer
    @check_connection_timer.cancel if @check_connection_timer
    @check_connection_timer = EM::Timer.new 100, method(:check_connection)
  end
end
