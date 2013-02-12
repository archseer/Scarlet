require 'socket'
require 'ipaddr'

module Scarlet
  module DCC
    module Outgoing

      class Connection < EventMachine::Connection
        def initialize(filename)
          @filename = filename
          # Wait 30s at most for a connection.
          @timeout_timer = EM::Timer.new 30, method(:close_connection_after_writing)
        end

        # Once the user connects, send file!
        def post_init
          # Stop timeout timer, we got a connection.
          @timeout_timer.cancel
          # Stream file and close server on success or error.
          streamer = stream_file_data(@filename)
          streamer.callback {close_connection_after_writing}
          streamer.errback {close_connection_after_writing}
        end
      end

      class Send
        attr_accessor :filename, :size

        def initialize(event, filename)
          @event = event
          @filename = filename
          @size = File.size(@filename)
          accept
        end

        def accept
          # start server on this computer and port 0 means start on any open port.
          @server = EM.start_server '0.0.0.0', 0, Connection, @filename

          sockname = EM.get_sockname(@server)
          @port, @ip = Socket.unpack_sockaddr_in(sockname)
          # @ip can be local, so assign to global
          @ip = Scarlet::DCC::IP

          @ip = "127.0.0.1" # Debug, local sends

          ip = IPAddr.new(@ip).to_i
          @event.ctcp "DCC SEND \"#{@filename}\" #{ip} #{@port} #{@size}"
        end
      end

    end
  end
end