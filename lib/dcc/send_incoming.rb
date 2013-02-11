#:Speed!~Speed@lightspeed.org PRIVMSG Scarletto :\u0001DCC CHAT chat 3232235782 37349\u0001
#:nightmare.uk.eu.synirc.net NOTICE Scarletto :Speed (~Speed@lightspeed.org) tried to DCC SEND you a file named 'slkrd', the request has been blocked.
#:nightmare.uk.eu.synirc.net NOTICE Scarletto :Files like these might contain malicious content (viruses, trojans). Therefore, you must explicitly allow anyone that tries to send you such files.
#:nightmare.uk.eu.synirc.net NOTICE Scarletto :If you trust Speed, and want him/her to send you this file, you may obtain more information on using the dccallow system by typing '/DCCALLOW HELP'
#:Speed!~Speed@lightspeed.org PRIVMSG Scarletto :\u0001DCC SEND 413456828_c524486c36_o.jpg 199 0 790829 91\u0001

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

        if @total == @send.size
          @io.flush
          @io.close
          @send.complete
          close_connection_after_writing
        end
      end

    end

    class OutConnection < EventMachine::Connection
      def initialize(send)
        @send = send
        @io = File.open(@send.filename, 'rb')
        @io.advise(:sequential)
      end

      # once the client connects, send file!
      def post_init
        send_file
      end

      def send_file
        chunk = @io.read(4096)
        send_data chunk

        # send next bit at next tick
        if !@io.eof?
          EM.next_tick {send_file}
        else # if we are at EOF, close server!
          @io.close
          @send.complete
          close_connection_after_writing
        end
      end
    end

    module Outgoing
      class Send
        attr_accessor :filename, :size

        def initialize(event, filename)
          @event = event
          @filename = filename
          #comm_inactivity_timeout
          #pending_connect_timeout
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

        def complete
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