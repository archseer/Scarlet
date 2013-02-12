require 'socket'
require 'ipaddr'

module Scarlet
  module DCC

    class Connection < EventMachine::Connection
      def initialize(send)
        @send = send
        if @send.pos
          @io = File.open(@send.filename, 'wb')
        else
          @io = File.open(@send.filename, 'ab')
        end
        @total = 0
      end

      def receive_data(data)
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

    module Incoming

      class Send
        attr_accessor :filename
        attr_reader :size, :pos

        def initialize(opts)
          @event, @filename, @ip, @port, @size, @token = opts.values_at(:event, :filename, :ip, :port, :size, :token)
          if File.exist?(@filename)
            @pos = File.size(@filename)
            resume
          else
            accept
          end
        end

        def accept
          @connection = EM.connect(config.address, config.port, Scarlet::DCC::Connection, self)
        end

        def resume
          @event.ctcp "DCC RESUME \"#{@filename}\" #{@port} #{@pos}"
        end
      end

      class ReverseSend < Send
        def accept
          # start server on this computer and port 0 means start on any open port.
          @server = EM.start_server '0.0.0.0', 0, Scarlet::DCC::Connection, self

          sockname = EM.get_sockname(@server)
          @port, @ip = Socket.unpack_sockaddr_in(sockname)

          # @ip can be local, so assign to global
          @ip = Scarlet::DCC::IP

          @ip = "127.0.0.1" # Debug, local sends
          ip = IPAddr.new(@ip).to_i
          @event.ctcp "DCC SEND \"#{@filename}\" #{ip} #{@port} #{@size} #{@token}"
        end
      end

    end
  end
end