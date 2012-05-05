class Scarlet::Connection < EM::Connection
  include EventMachine::Protocols::LineText2
  def initialize server
    @server = server
  end

  def post_init
    send_data "NICK #{@server.current_nick}"
    send_data "USER #{$config.irc_bot.host} #{@server.current_nick} #{@server.current_nick} :#{$config.irc_bot.name}"
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
    puts "Sending PING to server to verify connection..."
    @server.send_cmd :ping, :target => $config.irc_bot.server
    @check_connection_timer = EM::Timer.new(30, method(:timeout))
  end

  def timeout
    puts "Timed out waiting for server, reconnecting..."
    @server.send_cmd :quit, :quit => "Ping timeout"
    close_connection_after_writing
  end

  def reset_check_connection_timer
    @check_connection_timer.cancel if @check_connection_timer
    @check_connection_timer = EM::Timer.new(100, method(:check_connection))
  end
end