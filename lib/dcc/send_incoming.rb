require 'socket'
require 'ipaddr'

module Scarlet
  module DCC

    class Connection < EventMachine::Connection
      def initialize(send)
        @send = send
        @io = File.open(@send.filename, 'wb')
        @total = 0
      end

      def receive_data data
        @total += data.bytesize

        begin
          send_data [@total].pack("N")
        rescue Errno::EWOULDBLOCK, Errno::AGAIN
          # Nobody cares about ACKs, really. And if the sender couldn't
          # receive it at this point, he probably doesn't care, either.
        end

        @io << data
        @io.flush
        disconnect if @total == @send.size # Download complete!
      end

      def disconnect
        @io.close
        close_connection_after_writing
      end
    end

    class OutConnection < EventMachine::Connection
      def initialize(filename)
        @filename = filename
        @timeout_timer = EM::Timer.new 30, method(:disconnect) # Wait 30s at most for a connection.
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

    module Outgoing
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
          @server = EM.start_server '0.0.0.0', 0, Scarlet::DCC::OutConnection, @filename

          sockname = EM.get_sockname(@server)
          @port, @ip = Socket.unpack_sockaddr_in(sockname)
          # @ip can be local, so assign to global
          @ip = Scarlet::DCC::IP
          
          @ip = "127.0.0.1" # Debug, local sends

          ip = IPAddr.new(@ip).to_i
          @event.reply "\001DCC SEND \"#{@filename}\" #{ip} #{@port} #{@size}\001"
        end

      end

    end

    module Incoming

      class Send
        attr_accessor :filename, :size

        def initialize(opts)
          @event, @filename, @ip, @port, @size = opts.values_at(:event, :filename, :ip, :port, :size)
          accept
        end

        def accept
          @connection = EM.connect(config.address, config.port, Scarlet::DCC::Connection, self)
        end
      end

      class ReverseSend < Send
        def initialize(opts)
          super
          @port = nil
          @ip = nil
          @token = opts[:token]
        end

        def accept
          # start server on this computer and port 0 means start on any open port.
          @server = EM.start_server '0.0.0.0', 0, Scarlet::DCC::Connection, self

          sockname = EM.get_sockname(@server)
          @port, @ip = Socket.unpack_sockaddr_in(sockname)

          # @ip can be local, so assign to global
          @ip = Scarlet::DCC::IP

          @ip = "127.0.0.1" # Debug, local sends
          ip = IPAddr.new(@ip).to_i
          @event.reply "\001DCC SEND \"#{@filename}\" #{ip} #{@port} #{@size} #{@token}\001"
        end
      end

    end
  end
end