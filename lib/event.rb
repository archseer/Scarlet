class IRC
  class Event
    attr_accessor :server, :sender, :command, :params, :target, :channel

    def initialize(server, prefix, command, target, params)
      @server = server
      @sender = Sender.new(prefix)
      #unless @sender.server? and server.users.include? @sender.nick
      #  @sender.user = server.user[@sender.nick]
      #end
      @command = command
      @target = target
      @channel = target if target and target[0, 1] == '#'
      @params = params
    end


  end
end
