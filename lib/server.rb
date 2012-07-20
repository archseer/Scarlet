load "modules/scarlet/lib/output_helper.rb"
module Scarlet
  # All known modes
  @base_mode_list = {
    :owner      => {:name=>'owner'     ,:prefix=>'q',:symbol=>'~'},
    :admin      => {:name=>'admin'     ,:prefix=>'a',:symbol=>'&'},
    :op         => {:name=>'operator'  ,:prefix=>'o',:symbol=>'@'},
    :hop        => {:name=>'halfop'    ,:prefix=>'h',:symbol=>'%'},
    :voice      => {:name=>'voice'     ,:prefix=>'v',:symbol=>'+'},
    :registered => {:name=>'registered',:prefix=>'r',:symbol=>'' }
  }
  
  def self.base_mode_list; @base_mode_list; end

  class Server

    include ::OutputHelper

    attr_accessor :scheduler, :reconnect, :banned, :connection, :config, :handshake
    attr_reader :channels, :users, :extensions, :cap_extensions, :current_nick, :ircd
    attr_reader :base_mode_list, :mode_list, :vHost

    def initialize config  # irc could/should have own handlers.
      @config         = config
      @irc_commands   = YAML.load_file("#{Scarlet.root}/commands.yml").symbolize_keys!
      init
      # // Config
      @current_nick   = @config.nick
      @config[:control_char] ||= Scarlet.config.control_char
      @config = @config.dup.freeze
    end  

    def init
      @scheduler      = Scheduler.new
      @channels       = Scarlet::Channels.add_server(self.name) # holds data about the users on channel
      @users          = Scarlet::Users.add_server(self.name) # holds data on users (seen) on the server
      @banned         = []     # who's banned here?
      @modes          = []     # bot account's modes (ix,..)
      @extensions     = {}     # what the server-side supports (PROTOCTL)
      @cap_extensions = {}     # CAPability extensions (CAP REQ)
      @handshake      = false  # set to true after we connect (001)
      @reconnect      = true   # reconnection flag
      @vHost          = nil    # vHost/cloak
      @mode_list      = {} # Temp
    end

    def name
      @config[:server_name]
    end

    def disconnect
      send_cmd :quit, :quit => Scarlet.config.quit
      @reconnect = false
      connection.close_connection(true)
    end

    def unbind
      Channels.clean(self.name)
      Users.clean(self.name)
      @modes.clear
      @extensions.clear
      @banned.clear
      @cap_extensions.clear

      reconnect = lambda {
        puts "Connection to server lost. Reconnecting...".light_red
        connection.reconnect(@config.address, @config.port) rescue return EM.add_timer(3) { reconnect.call }
        connection.post_init
        init
      }
      EM.add_timer(3) { reconnect.call } if @reconnect
    end

    def send_data data
      if data =~ /(PRIVMSG|NOTICE)\s(\S+)\s(.+)/i
        stack = []
        command, trg, text = $1, $2, $3
        length = 510 - command.length - trg.length - 2 - 120
        text.word_wrap(length).split("\n").each do |s| stack << '%s %s %s' % [command,trg,s] end
      else
        stack = [data]
      end
      stack.each do |d| connection.send_data d end
      nil
    end

    def receive_line line
      parsed_line = IRC::Parser.parse line
      event = IRC::Event.new(:localhost, parsed_line[:prefix],
                        parsed_line[:command].downcase.to_sym,
                        parsed_line[:target], parsed_line[:params])
      Log.write(event)
      handle_event event
    end

    #----------------------------------------------------------
    def send_cmd cmd, hash
      send_data Mustache.render(@irc_commands[cmd], hash)
    end

    def msg target, message, silent=false
      send_data "PRIVMSG #{target} :#{message}"
      write_log :privmsg, message, target
      print_chat @current_nick, message, silent unless silent
    end

    def notice target, message, silent=false
      send_data "NOTICE #{target} :#{message}"
      write_log :notice, message, target
      print_console ">#{target}< #{message}", :light_cyan unless silent
    end

    def write_log command, message, target
      return if target =~ /Serv$/ # if we PM a bot, i.e. for logging in, that shouldn't be logged.
      log = Log.new(:nick => @current_nick, :message => message, :command => command.upcase, :target => target)
      log.channel = target if target.starts_with? "#"
      log.save!
    end

    def check_ns_login nick
      # According to the docs, those servers that use STATUS may query up to
      # 16 nicknames at once. if we pass an Array do:
      #   a) on STATUS send groups of up to 16 nicknames
      #   b) on ACC, we have no such luck, send each message separately.

      if nick.is_a? Array
        if @ircd =~ /unreal/i
          nick.each_slice(16) {|group| msg "NickServ", "STATUS #{group.join(' ')}", true}
        else
          nick.each {|nickname| msg "NickServ", "ACC #{nick}", true}
        end 
      else # one nick was given, send the message
        msg "NickServ", "ACC #{nick}", true if @ircd =~ /ircd-seven/i # freenode
        msg "NickServ", "STATUS #{nick}", true if @ircd =~ /unreal/i
      end

    end
  end
end