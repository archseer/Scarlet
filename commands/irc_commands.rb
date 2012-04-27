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
              cmd[:help].each { |line| msg target, line }
            else
              msg target, cmd[:help]
            end
          else
            data = {:params => params, :sender => event.sender.nick, :target => event.target} #here we set the data we pass
            result = (self.instance_exec data, &block) #here we exec the function

            if result.is_a?(Array) #result processing
              result.each { |line| msg target, line, true }
            elsif result.is_a?(String)
              msg target, result
            end
          end
        }
      end
    end
  end

  class BotCommands < Command
    commands_scope :return_to_sender
    access_levels :toggle => :dev
    arities :toggle => 1

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