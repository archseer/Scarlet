require 'socket'
require 'ipaddr'

class Scarlet
  module DCC
    module Incoming
      class Connection < EventMachine::Connection
        def initialize(send)
          @send = send
          @io = File.open(@send.filename, @send.pos ? 'ab' : 'wb')
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
          @connection = EM.connect(@ip, @port, Connection, self)
        end

        def resume
          @event.ctcp "DCC", "RESUME \"#{@filename}\" #{@port} #{@pos}"
        end
      end

      class ReverseSend < Send
        def accept
          # start server on this computer and port 0 means start on any open port.
          @server = EM.start_server '0.0.0.0', 0, Connection, self

          @ip, @port = Scarlet::DCC.get_ip_port(@server)

          @event.ctcp "DCC", "SEND \"#{@filename}\" #{@ip} #{@port} #{@size} #{@token}"
        end
      end
    end
  end
end
