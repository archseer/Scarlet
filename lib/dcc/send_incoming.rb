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
          # Nobody cares about ACKs, really. And if the sender
          # couldn't receive it at this point, he probably doesn't
          # care, either.
        end

        @io << data
        disconnect if @total == @send.size # Download complete
      end

      def disconnect
        @io.close
        @send.complete if @send.respond_to? :complete
        close_connection_after_writing
      end
    end

    class OutConnection < EventMachine::Connection
      def initialize(send)
        @send = send
        @timeout_timer = EM::Timer.new 30, method(:disconnect) # Wait 30s at most for a connection.
      end

      # Once the client connects, send file!
      def post_init
        @timeout_timer.cancel # Stop timeout timer, we got a connection.
        streamer = stream_file_data @send.filename
        streamer.callback {disconnect}
        streamer.errback {disconnect}
      end

      def disconnect
        @io.close
        @send.complete if @send.respond_to? :complete
        close_connection_after_writing
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
          @server = EM.start_server '0.0.0.0', 0, Scarlet::DCC::OutConnection, self

          sockname = EM.get_sockname(@server)
          @port, @ip = Socket.unpack_sockaddr_in(sockname)
          # @ip can be local, so assign to global
          @ip = Scarlet::DCC::IP
          
          @ip = "127.0.0.1" # Debug, local sends

          ip = IPAddr.new(@ip).to_i
          @event.reply "\001DCC SEND \"#{@filename}\" #{ip} #{@port} #{@size}\001"
        end

        # Stop the server on complete.
        def complete
          EM.stop_server @server
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
          @port, address = Socket.unpack_sockaddr_in(sockname)

          # Hack, get IP
          @ip = %x{curl -s checkip.dyndns.org | grep -Eo '[0-9\.]+'}.delete("\n")
          # Debug, local sends
          @ip = "127.0.0.1"
          ip = IPAddr.new(@ip).to_i
          @event.reply "\001DCC SEND \"#{@filename}\" #{ip} #{@port} #{@size} #{@token}\001"
        end

        # Stop the server on complete.
        def complete
          EM.stop_server @server
        end
      end

    end
  end
end