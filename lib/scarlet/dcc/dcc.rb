module Scarlet
  module DCC
    class Event
      attr_reader :sender, :server, :command, :params, :type
      def initialize(event)
        @sender = event.sender
        @server = event.server

        matches = event.params.first.match(/\001(?<command>\S+)\s*(?<params>.*)\001/)
        @command = matches['command'].to_sym

        # Split params into space separated sections, unless quoted.
        # http://stackoverflow.com/questions/13040585/
        @params = matches['params'].scan(/(?:"(?:\\.|[^"])*"|[^" ])+/)

        if @command == :DCC
          @dcc = true
          @type = @params.shift.to_sym
        end
      end

      def dcc?
        !!@dcc
      end

      def reply message
        @server.msg @sender.nick, "#{message}"
      end

      # Sends a NOTICE reply back to the sender (a user).
      # @param [String] message The message to send back.
      def notify message
        @server.notice @sender.nick, message
      end

      # Send a reply back as a ctcp message.
      def ctcp message
        reply "\001#{message}\001"
      end
    end

    # Hack, get IP
    def self.ip
      @ip ||= %x{curl -s checkip.dyndns.org | grep -Eo '[0-9\.]+'}.delete("\n")
    end

    def self.handle_dcc event
      case event.type
      when :SEND
        process_dcc_send(event)
      when :ACCEPT
      when :RESUME
      end
    end

    def self.process_dcc_send event
      filename, ip, port, size, token = event.params
      # ugly remove leading and trailing quote
      filename = filename.chomp('"').reverse.chomp('"').reverse
      ip = IPAddr.new_ntoh([ip.to_i].pack("N")).to_s
      port = port.to_i
      size = size.to_i

      if port == 0 && token # Reverse Send, used for firewalled connections
        Scarlet::DCC::Incoming::ReverseSend.new event: event, filename: filename, size: size, token: token
      else # Send
        Scarlet::DCC::Incoming::Send.new event: event, filename: filename, size: size, ip: ip, port: port
      end
    end

    def self.send event, filename
      Scarlet::DCC::Outgoing::Send.new event, filename
    end
  end
end
