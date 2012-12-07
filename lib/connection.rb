# an "adapter" that provides basic IRC initialization and automated timeout checking
class Scarlet::Connection < EM::Connection
  include EventMachine::Protocols::LineText2
  def initialize server
    @server = server
  end

  def post_init
    send_data "CAP LS" # CAP extension http://ircv3.atheme.org/ (freenode)
    send_data "NICK #{@server.current_nick}"
    send_data "USER #{Scarlet.config.host} * * :#{Scarlet.config.name}"
    reset_check_connection_timer
  rescue => e
    p e
  end

  def receive_line line
    reset_check_connection_timer
    @server.receive_line(RUBY_VERSION < "1.9" ? line : line.force_encoding('utf-8'))
  end

  def send_data data
    super "#{data}\r"
  end

  def unbind
    @check_connection_timer.cancel if @check_connection_timer
    @server.unbind
  end

  private
  def check_connection
    #print "Sending PING to server to verify connection..."
    send_data "PING #{@server.config.address}"
    @check_connection_timer = EM::Timer.new 30, method(:timeout)
  end

  def timeout
    print "Timed out waiting for server, reconnecting...".light_red
    send "QUIT :Ping timeout"
    close_connection_after_writing
  end

  def reset_check_connection_timer
    @check_connection_timer.cancel if @check_connection_timer
    @check_connection_timer = EM::Timer.new 100, method(:check_connection)
  end
end