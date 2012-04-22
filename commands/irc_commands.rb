require_relative "../lib/monkeypatches.rb"

module ::IrcBot::User ; end

module IrcBot::IrcCommands
  Commands = ::IrcBot.commands
  Todo = ::IrcBot::Todo
  Nick = ::IrcBot::Nick
  User = ::IrcBot::User

  class Command
    class << self
      @@access_level = {:any => 0, :registered => 1, :voice => 2, :vip => 3, :super_tester => 6, :op => 7, :dev => 8, :owner => 9}
      @@permissions = {}
      @@help = {}
      @@arity = {}
      @@table = nil

      def commands_scope scope
        @@scope = scope
      end

      def generate_table t
        @@table = t
      end

      def access_levels l = {}
        @@permissions.merge! l
      end

      def help h = {}
        @@help.merge! h
      end

      def arities a = {}
        @@arity.merge! a
      end

      def on keyword, &block
        Commands[keyword] = { :arity => @@arity[keyword], :scope => @@scope, :help => @@help[keyword], :disable => false,
                              :table => @@table, :access_level => @@access_level[@@permissions[keyword]]  }
        cmd = Commands[keyword]

        cmd[:method] = Proc.new { |params, event|
          # sets the target
          case cmd[:scope]
            when :return_to_sender
              target = event.target == $config.irc_bot.nick ? event.sender.nick : event.target
            when :user
              target = event.sender.nick
          end
          # arity check
          if cmd[:arity] && !(cmd[:arity].is_a?(Range) ? cmd[:arity].member?(params.split(" ").length) : params.split(" ").length == cmd[:arity])
            if cmd[:help].is_a?(Array)
              cmd[:table] ? create_table(cmd[:help], 40).each { |line| msg target, line } : cmd[:help].each { |line| msg target, line }
            else
              msg target, cmd[:help]
            end
          else
            data = {:params => params, :sender => event.sender.nick, :target => event.target} #here we set the data we pass
            result = (self.instance_exec data, &block) #here we exec the function

            if result.is_a?(Array) #result processing
              #cmd[:table] ? create_table(result, cmd[:table]).each { |line| msg target, line, true } : 
              result.each { |line| msg target, line, true }
            elsif result.is_a?(String)
              msg target, result
            end
          end
        }
      end
    end
  end

  class BotServ < Command
    commands_scope :return_to_sender
    access_levels :register => :any, :login => :any, :logut => :any, :alias => :registered
    arities :register => 0, :login => 0, :logout => 0

    on :register do |data|
      if User.ns_login? @channels, data[:sender]
        if Nick.where(:nick => data[:sender]).empty?
          nick = Nick.new(:nick => data[:sender]).save!
          "Successfuly registered with the bot."
        else
          "ERROR: You are already registered!".irc_color(4,0)
        end
      else
        "You must login with NickServ first!"
      end
    end

    on :login do |data|
      if !Nick.where(:nick => data[:sender]).empty?
        if !User.ns_login? @channels, data[:sender]
          check_nick_login data[:sender]
        else
          notice data[:sender], "#{data[:sender]}, you are already logged in!"
        end
      else
        notice data[:sender], "#{data[:sender]}, you do not have an account yet. Type !register."
      end
    end

    on :logout do |data|
      if User.ns_login? @channels, data[:sender]
        User.ns_logout @channels, data[:sender]
        notice data[:sender], "#{data[:sender]}, you are now logged out."
      end
    end

    on :alias do |data|
      # implement a command where we can 'alias' nicknames
    end
  end

  class HelpCommand < Command
    commands_scope :user
    access_levels :help => :any
    arities :help => 0..Float::INFINITY
    generate_table 70

    on :help do |data|
      if data[:params].blank?
        hlp = ["Help for [Bot]"]
        cmd = []
        devcmd =[]
        Commands.keys.each { |k| Commands[k.to_sym][:access_level] ? (Commands[k.to_sym][:access_level] > 1 ? devcmd << k.to_s : cmd << k.to_s) : cmd << k}
        ["Help for [Bot]", "Devel. commands available: #{devcmd.join(" ")}", "Commands available: #{cmd.join(" ")}"]
      else
        Commands[data[:params].to_sym][:help]
      end
    end
  end

  class BotCommands < Command
    commands_scope :return_to_sender
    access_levels :eval => :dev, :toggle => :dev
    help :eval => "Usage: eval <ruby code>"
    arities :eval => 1..Float::INFINITY, :toggle => 1

    on :eval do |data|
      if !Nick.where(:nick => data[:sender]).empty? && Nick.where(:nick => data[:sender]).first.privileges == 9
        params = data[:params]
      else
        safe = true
        names_list = ["a poopy-head", "a meanie", "a retard", "an idiot"]
        if data[:params].match(/(.*(Thread|Process|File|Kernel|system|Dir|IO|fork|while\s*true|require|load|ENV|%x|\`|sleep|Modules|Socket|send|undef|\/0|INFINITY|loop|variable_set|\$|@|Nick.*privileges.*save!|disconnecting\s*\=\s*true).*)/) 
          params = "\"#{data[:sender]} is #{names_list[rand(4)-1]}.\"" 
        else 
          params = data[:params]
        end
        params.taint
      end

      begin
        t = Thread.new {
          Thread.current[:output] = "==> #{eval(params)}"
        }
        t.join(10)
        t[:output]
      rescue(Exception) => result
        "ERROR: #{result.message}".irc_color(4,0)
      end
    end

    on :toggle do |data|
      cmd = data[:params].strip.to_sym
      if cmd && cmd != :toggle
        if cmd != :eval
          if Commands.has_key?(cmd)
            Commands[cmd][:disable] = !Commands[cmd][:disable]
            "Command '#{data[:params]}' is now #{Commands[cmd][:disable] ? "disabled" : "enabled"}."
          else
            "Cannot toggle: Command '#{data[:params]}' does not exist."
          end
        else
          n = Nick.where(:nick => data[:sender])
          if n.count > 0 and n.first.privileges == 9 # quick fix
            Commands[:eval][:disable] = !Commands[:eval][:disable]
            "Command 'eval' is now #{Commands[:eval][:disable] ? "disabled" : "enabled"}."
          else
            "#{data[:sender]}, you do not have permission to use #{data[:params]}!"
          end
        end
      else
        "You cannot toggle :toggle!" if cmd == :toggle
      end
    end
  end
end