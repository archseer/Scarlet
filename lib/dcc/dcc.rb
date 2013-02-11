module Scarlet
  module DCC
    # Hack, get IP
    IP = %x{curl -s checkip.dyndns.org | grep -Eo '[0-9\.]+'}.delete("\n")

    def self.handle_request(event)
      matches = event.params.first.match(/\001DCC (?<type>\S+) (?<params>.+)\001/)
      command = Hash[ matches.names.map(&:to_sym).zip( matches.captures ) ]
      # Split params into space separated sections, unless quoted.
      # http://stackoverflow.com/questions/13040585/ 
      command[:params] = command[:params].scan(/(?:"(?:\\.|[^"])*"|[^" ])+/)
      case command[:type]
      when "SEND"
        process_dcc_send(event, command)
      when "ACCEPT"
      when "RESUME"
      end
    end

    def self.process_dcc_send event, command
      filename, ip, port, size, token = command[:params]
      # ugly remove leading and trailing quote
      filename = filename.chomp('"').reverse.chomp('"').reverse
      ip = ip.to_i
      ip = [24, 16, 8, 0].collect {|b| (ip >> b) & 255}.join('.')
      port = port.to_i
      size = size.to_i

      if port == 0 && token # Reverse Send, used for firewalled connections
        Scarlet::DCC::Incoming::ReverseSend.new(event: event, filename: filename, size: size, token: token)
      else # Send
        Scarlet::DCC::Incoming::Send.new(event: event, filename: filename, size: size, token: token)
      end
    end

    def self.send event, filename
      Scarlet::DCC::Outgoing::Send.new(event, filename)
    end

  end
end